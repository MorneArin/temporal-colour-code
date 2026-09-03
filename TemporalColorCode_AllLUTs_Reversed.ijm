// TemporalColorCode_AllLUTs_Reversed.ijm
//
// Same as TemporalColorCode_AllLUTs.ijm, but the z-stack's slice/frame order
// is reversed before color coding, so the temporal color mapping runs from
// the LAST frame (start of the LUT) to the FIRST frame (end of the LUT).
//
// A reversed duplicate is made once up front; the original stack is left
// completely untouched and open throughout. Output PNGs get a "_reversed"
// suffix so they won't collide with a normal (non-reversed) run into the
// same folder.
//
// Run this with your z-stack window ACTIVE in Fiji:
//   File > New > Script... (language: IJM), paste, Run
//   (or Plugins > New > Macro, paste, Run)

var Glut = "Fire";
var Gmethod = "MAX";                // "MAX", "SUM", or "WeightedSUM"
var Gstartf = 1;
var Gendf = 1;
var GFrameColorScaleCheck = false;  // scale bar disabled
var GbatchMode = true;

macro "Temporal Color Code - All LUTs (Reversed)" {
    if (nImages == 0) exit("No image is open.");
    origID = getImageID();
    srcTitle = getTitle();

    Stack.getDimensions(ww, hh, channels, slices, frames);
    if (channels > 1)
        exit("Cannot color-code multi-channel images!");
    if ((slices > 1) && (frames == 1)) {
        frames = slices;
        slices = 1;
        Stack.setDimensions(1, slices, frames);
        print("slices and frames swapped");
    }

    // Build a reversed duplicate to process; original stack stays untouched.
    selectImage(origID);
    run("Duplicate...", "duplicate");
    run("Reverse");
    srcID = getImageID();
    rename(srcTitle + " (reversed)");

    outputDir = getDirectory("Choose a folder to save the PNGs");

    lutA = makeLUTsArray();
    print("Found " + lutA.length + " LUTs under Image>Lookup Tables. Processing '" + srcTitle + "' in reverse order...");

    Gmethod = "MAX";
    Gstartf = 1;
    Gendf = frames;
    GFrameColorScaleCheck = false;
    GbatchMode = true;

    processed = 0;
    for (lutIndex = 0; lutIndex < lutA.length; lutIndex++) {
        Glut = lutA[lutIndex];
        showStatus("Temporal-Color Code: " + Glut + " (" + (lutIndex + 1) + "/" + lutA.length + ")");

        selectImage(srcID);

        // Note: this macro interpreter doesn't support try/catch, so a failure
        // on any single LUT will stop the whole run rather than being skipped.
        resultID = runColorCode(srcID, ww, hh, channels, slices, frames);

        if (resultID != -1) {
            selectImage(resultID);
            safeName = replace(Glut, "/", "-");
            safeName = replace(safeName, "\\\\", "-");
            savePath = outputDir + safeName + "_reversed.png";
            saveAs("PNG", savePath);
            close();
            print("Saved: " + savePath);
            processed++;
        }
    }

    selectImage(srcID);
    close();

    selectImage(origID);
    setBatchMode("exit and display");
    print("Done. Saved " + processed + " / " + lutA.length + " PNGs to " + outputDir);
}

// ---- Core color-coding routine, adapted from Kota Miura's Temporal-Color Code
//      plugin (Dialog.* removed; driven by the globals set above) ----
function runColorCode(srcID, ww, hh, channels, slices, frames) {
    setBatchMode(true);

    if (Gmethod == "WeightedSUM") {
        selectImage(srcID);
        titleorig = getTitle();
        run("Duplicate...", "duplicate");
        stackcopy = getImageID();
        run("Z Project...", "projection=[Sum Slices]");
        brightness = getImageID();
        rename("brightness");
        selectImage(stackcopy);

        run("32-bit");
        for (i = 0; i < nSlices; i++) {
            setSlice(i + 1);
            colorscale = round((256 / nSlices) * (i + 1));
            run("Multiply...", "value=" + toString(colorscale) + " slice");
        }
        run("Z Project...", "projection=[Sum Slices]");
        rename("weighted");
        weightedID = getImageID();
        imageCalculator("Divide create 32-bit", "weighted", "brightness");
        huemap = getImageID();
        selectImage(weightedID);
        close();
        selectImage(stackcopy);
        close();
        selectImage(huemap);
        getStatistics(area, mean, minI, maxI);
        setMinAndMax(minI, maxI);
        run(Glut);
        run("RGB Color");
        run("HSB Stack");

        selectImage(brightness);
        run("Enhance Contrast", "saturated=0.35");
        run("8-bit");
        run("Select All");
        run("Copy");
        selectImage(huemap);
        setSlice(3);
        run("Paste");
        run("RGB Color");
        selectImage(brightness);
        close();
        selectImage(huemap);
        rename("weightedSUM_" + titleorig);
        return huemap;
    } else {
        sf = Gstartf; ef = Gendf;
        if (sf < 1) sf = 1;
        if (ef > frames) ef = frames;
        totalframes = ef - sf + 1;
        calcslices = slices * totalframes;

        newImage("colored", "RGB White", ww, hh, calcslices);
        run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices="
            + slices + " frames=" + totalframes + " display=Color");
        newimgID = getImageID();

        selectImage(srcID);
        run("Duplicate...", "duplicate");
        run("8-bit");
        dupID = getImageID();

        newImage("stamp", "8-bit White", 10, 10, 1);
        run(Glut);
        getLut(rA, gA, bA);
        close();
        nrA = newArray(256);
        ngA = newArray(256);
        nbA = newArray(256);

        newImage("temp", "8-bit White", ww, hh, 1);
        tempID = getImageID();

        for (i = 0; i < totalframes; i++) {
            colorscale = floor((256 / totalframes) * i);
            for (j = 0; j < 256; j++) {
                intensityfactor = j / 255;
                nrA[j] = round(rA[colorscale] * intensityfactor);
                ngA[j] = round(gA[colorscale] * intensityfactor);
                nbA[j] = round(bA[colorscale] * intensityfactor);
            }

            for (j = 0; j < slices; j++) {
                selectImage(dupID);
                Stack.setPosition(1, j + 1, i + sf);
                run("Select All");
                run("Copy");

                selectImage(tempID);
                run("Paste");
                setLut(nrA, ngA, nbA);
                run("RGB Color");
                run("Select All");
                run("Copy");
                run("8-bit");

                selectImage(newimgID);
                Stack.setPosition(1, j + 1, i + 1);
                run("Select All");
                run("Paste");
            }
        }

        selectImage(tempID);
        close();

        selectImage(dupID);
        close();

        selectImage(newimgID);
        run("Stack to Hyperstack...", "order=xyctz channels=1 slices="
            + totalframes + " frames=" + slices + " display=Color");

        if (Gmethod == "MAX")
            op = "start=1 stop=" + ef + " projection=[Max Intensity] all";
        else
            op = "start=1 stop=" + ef + " projection=[Sum Slices] all";
        run("Z Project...", op);

        if (slices > 1)
            run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices=" + slices
                + " frames=1 display=Color");
        resultImageID = getImageID();

        selectImage(newimgID);
        close();

        if (GFrameColorScaleCheck)
            CreateScale(Glut, sf, ef);

        return resultImageID;
    }
}

// ---- LUT enumeration ----
// The original plugin builds this list via eval("script", ...) (Rhino/JavaScript)
// introspecting the Image>Lookup Tables menu, and a folder-scan fallback missed
// several entries. This is the exact, verbatim list read off the plugin's own
// "Color Code Settings" LUT dropdown, in the order it appears there.
function makeLUTsArray() {
    return newArray(
        "Fire", "Grays", "Ice", "Spectrum", "3-3-2 RGB", "Red", "Green", "Blue",
        "Cyan", "Magenta", "Yellow", "Red/Green",
        "16 colors", "5 ramps", "6 shades", "blue orange icb", "brgbcmyw", "cool",
        "Cyan Hot", "edges", "gem", "glasbey", "glasbey inverted", "glasbey on dark",
        "glow", "Green Fire Blue", "Hi", "HiLo", "ICA", "ICA2", "ICA3", "Magenta Hot",
        "mpl-inferno", "mpl-magma", "mpl-plasma", "mpl-viridis", "Orange Hot", "phase",
        "physics", "Rainbow RGB", "Red Hot", "royal", "sepia", "smart", "thal",
        "thallium", "Thermal", "unionjack", "Yellow Hot"
    );
}

function CreateScale(lutstr, beginf, endf) {
    ww2 = 256;
    hh2 = 32;
    newImage("color time scale", "8-bit White", ww2, hh2, 1);
    for (j = 0; j < hh2; j++) {
        for (i = 0; i < ww2; i++) {
            setPixel(i, j, i);
        }
    }
    run(lutstr);
    run("RGB Color");
    op = "width=" + ww2 + " height=" + (hh2 + 16) + " position=Top-Center zero";
    run("Canvas Size...", op);
    setFont("SansSerif", 12, "antiliased");
    run("Colors...", "foreground=white background=black selection=yellow");
    drawString("frame", round(ww2 / 2) - 12, hh2 + 16);
    drawString(leftPad(beginf, 3), 0, hh2 + 16);
    drawString(leftPad(endf, 3), ww2 - 24, hh2 + 16);
}

function leftPad(n, width) {
    s = "" + n;
    while (lengthOf(s) < width)
        s = "0" + s;
    return s;
}
