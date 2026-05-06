# Dataset Creator — Interactive YOLO Annotation Tool with SAM3

A frame-by-frame video annotation tool that produces YOLO-format datasets.
It combines manual bounding-box editing with SAM3-powered semi-automatic tracking.

---

## Usage

```bash
python main.py \
    --folder  /path/to/save/dataset \
    --video   /path/to/source.mp4 \
    [--fps    10.0] \
    [--model  sam3.pt]
```

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `--folder` | Yes | — | Output directory. Sub-folders `images/` and `labels/` are created automatically. |
| `--video` | Yes | — | Source video file used for frame rendering and SAM3 tracking. |
| `--fps` | No | `10.0` | Playback speed in Play mode (frames per second). |
| `--model` | No | `sam3.pt` | SAM3 model weights file. |

When the editor is closed a `config.txt` summary file is written to `--folder`.

---

## Output structure

```
<folder>/
├── images/
│   ├── frame_000000.jpg
│   ├── frame_000042.jpg
│   └── ...
├── labels/
│   ├── frame_000000.txt
│   ├── frame_000042.txt
│   └── ...
├── _deleted/          ← frames moved here by the Delete action
├── _tmp/              ← temporary SAM3 sub-clips (auto-deleted)
└── config.txt         ← session summary written on exit
```

Each label file uses the standard YOLO format:

```
<class_id> <x_center> <y_center> <width> <height>
```

All values are normalised to [0, 1] relative to the frame dimensions.
Only frames that carry at least one bounding box are saved (image + label file).
If all boxes are removed from a frame, both files are deleted automatically.

---

## GUI overview

The main window is split into three areas:

```
┌──────────────────────────────────────────────────┐
│                 frame display                    │  ← main canvas (zoomable)
├──────────────────────────────────────────────────┤
│                  frame slider                    │
├──────────────────────────────────────────────────┤
│  -100  -10  -1  Pause  +1  +10  +100  Delete  SAM  Stop  │  Mode SAM: [Merge] Replace
└──────────────────────────────────────────────────┘
```

A status bar at the top of the canvas shows the current frame index, annotation state, and SAM status.

---

## Features

### Frame navigation

| Action | Description |
|--------|-------------|
| **Slider** | Click or drag to jump to any frame instantly. |
| **Play / Pause** (button or `Space`) | Plays the video forward at the configured FPS. |
| **−1 / +1** (buttons or `←` / `→`) | Step one frame back / forward. |
| **−10 / +10** (buttons or `A` / `E`) | Step 10 frames back / forward. |
| **−100 / +100** (buttons or `W` / `C`) | Step 100 frames back / forward. |

### Manual bounding-box annotation

#### Drawing a box

1. Press `N` (or a digit key `0`–`9`) to enter **Draw mode** — the cursor becomes a crosshair and a live preview rectangle follows the mouse.
   - Pressing a digit key pre-selects the class for that box; no dialog will appear on release.
   - Pressing `N` without a digit shows a dialog to enter the class ID after you finish drawing.
2. Click and drag on the canvas to draw the box.
3. On release the box is saved immediately.
   - Pressing the same digit key again while already in Draw mode for that class exits Draw mode.
   - `Escape` exits Draw mode without saving.

#### Selecting and editing a box

- **Left-click inside a box** — selects it (solid border + 8 resize handles).
- **Drag the box body** — moves the entire box.
- **Drag a corner or edge handle** — resizes the box non-uniformly:
  - 4 corners: top-left, top-right, bottom-left, bottom-right
  - 4 edge mid-points: top-center, bottom-center, left-center, right-center
- Changes are saved automatically on mouse release.

#### Deleting a box

| Method | Behaviour |
|--------|-----------|
| **Right-click** on a box | First click selects it; second right-click on the already-selected box deletes it. |
| **Erase mode** (`K`) | Left-click on any box deletes it immediately. A red `GOMME [k]` indicator appears in the bottom-right corner. Press `K` again or `Escape` to exit. |

#### Deleting an entire annotated frame

Press `Delete` or the **Delete** button to move the current frame's image and label files to `_deleted/` (timestamped to avoid collisions). The frame itself remains navigable in the video — only the saved annotation files are removed.

### Zoom and pan

| Action | Effect |
|--------|--------|
| `Ctrl + scroll wheel` | Zoom in / out centred on the cursor. |
| `+` / `=` | Zoom in by ×1.25. |
| `-` | Zoom out by ×1.25. |
| `.` | Reset zoom to full view. |
| **Left-drag on empty area** (when zoomed) | Pan the view. |

Zoom state is preserved when navigating between frames.

### Hide / show boxes

Hold `R` to temporarily hide all bounding boxes and see the raw frame. Release `R` to restore them. A small `image brute [r]` indicator appears while boxes are hidden.

### Class colour legend

When the current frame contains at least one annotation, a colour legend is displayed in the bottom-left corner of the canvas. The label displayed for each class is read from `CLASS_NAMES` in `config.py` (see [Customising class names](#customising-class-names-in-configpy)).

---

## SAM3 semi-automatic tracking

SAM3 propagates bounding boxes forward through the video from the current frame, using `ultralytics.models.sam.SAM3VideoPredictor`.

### Launching a tracking session

1. Navigate to the frame where the object(s) first appear clearly.
2. Press `S` or click the **SAM** button.
3. A dialog appears with three fields:
   - **Number of objects to track** — how many objects SAM3 will follow simultaneously.
   - **Class IDs** — space-separated list of class IDs, one per object (e.g. `0 1 2`). Pre-filled from the current frame's annotations.
   - **Number of negative bboxes** — zones SAM3 should *ignore* (0 = none).
4. Click **Launch SAM3** (or press `Enter`).
5. For each **positive** object a box-selector window opens on the current frame:
   - Draw a box around the target object.
   - Boxes already defined appear as reference overlays.
   - `Enter` / `Space` — confirm; `Escape` — cancel the whole session; `R` — redraw.
6. For each **negative** box (if requested) the same selector opens with a red border — draw around the region SAM3 should treat as background.
7. Tracking starts immediately in a background thread.

### Box-selector controls

| Key / action | Effect |
|---|---|
| **Drag** | Draw a new bounding box. |
| `Enter` / `Space` | Validate the current box. |
| `Escape` | Cancel the entire SAM session. |
| `R` | Clear the current box and start over. |
| `Ctrl + drag` | Pan the view. |
| `Ctrl + scroll` / `+` / `-` | Zoom in / out. |
| `.` | Reset zoom. |

### During tracking

The main canvas updates in real time, showing the current frame with SAM3 predictions overlaid (coloured boxes labelled `OK` or `PERDU N`).

The status bar shows:
```
SAM3 EN COURS  |  frame 42  |  2/2 detecté(s)  |  Obj1=OK  Obj2=OK  |  X=stopper
```

Press `X` or click the **Stop** button to interrupt tracking at any time.

### Automatic stop

Tracking stops automatically when any tracked object has been **lost** for more than `lost_threshold` consecutive frames (default: 15). The editor then returns to the last processed frame.

### Merge mode

A clickable text label to the right of the toolbar controls how SAM3 results are written when a label file for a frame already exists:

| Mode | Behaviour |
|------|-----------|
| **Merge** (default) | New SAM3 lines are *appended* to the existing label file. Pre-existing annotations from other classes are kept. |
| **Replace** | Lines whose class ID matches one of the tracked classes are *removed* and replaced by the SAM3 predictions. Other classes are untouched. |

Click the label to toggle between modes. The active mode is shown in brackets.

---

## Session summary (`config.txt`)

On exit, a `config.txt` file is written to `--folder` containing:

```
Date           : 2026-05-05 15:50:00
Video          : /path/to/video.mp4
N objects      : 1
Class-ids      : [0]
Conf           : 0.35
Lost threshold : 15
SAM3 sessions  : 1          ← number of SAM3 tracking sessions launched
Images         : 68
Labels         : 68         ← non-empty label files
Time           : 0:01:10
```

---

## Customising class names in `config.py`

The file [config.py](config.py) is the single place to configure the visual appearance of class labels.

### `CLASS_NAMES`

```python
CLASS_NAMES: dict = {
    0: "Squid",
    1: "Sardine",
    2: "Ray",
    3: "Sunfish",
    4: "Pilot Fish",
    5: "Shark",
}
```

- **Keys** are integer class IDs matching the first column in YOLO label files.
- **Values** are the human-readable strings shown in the canvas legend and in dialogs.
- Add, remove, or rename entries freely.
- Any class ID not present in the dict falls back to `cls <id>` in the legend.

### Colour palettes

Three palettes are defined — one per rendering backend. They cycle automatically when the class ID exceeds the palette length.

| Variable | Used by | Format |
|----------|---------|--------|
| `_PALETTE_RGB` | matplotlib canvas (boxes, legend) | `(R, G, B)` floats in `[0, 1]` |
| `_PALETTE_BGR` | OpenCV overlays during SAM3 tracking | `(B, G, R)` ints in `[0, 255]` |
| `_PALETTE_PIL` | Tkinter box-selector window | `(R, G, B)` ints in `[0, 255]` |

To change the colour of class 0, update index 0 in all three palettes consistently.

Example — replacing the default red (class 0) with a teal tone:

```python
_PALETTE_RGB = [
    (0.10, 0.75, 0.70),   # class 0 → teal  (R, G, B floats)
    ...
]

_PALETTE_BGR = [
    (180, 190,  25),       # class 0 → teal  (B, G, R ints)
    ...
]

_PALETTE_PIL = [
    ( 25, 190, 180),       # class 0 → teal  (R, G, B ints)
    ...
]
```

### Other constants

| Constant | Default | Effect |
|----------|---------|--------|
| `HANDLE_RADIUS` | `8` | Pixel radius of the resize-handle hit-zone around each corner and edge mid-point. Increase if handles are hard to grab. |
| `NEW_BOX_MIN` | `5` | Minimum width **and** height (in pixels) for a newly drawn box to be accepted. Boxes smaller than this threshold are discarded silently. |

---

## Keyboard shortcuts summary

| Key | Action |
|-----|--------|
| `Space` | Play / Pause |
| `←` / `→` | −1 / +1 frame |
| `A` / `E` | −10 / +10 frames |
| `W` / `C` | −100 / +100 frames |
| `N` | Toggle Draw mode (prompts for class ID on release) |
| `0`–`9` | Enter Draw mode pre-selecting that class ID |
| `K` | Toggle Erase mode |
| `R` (hold) | Hide bounding boxes temporarily |
| `Delete` | Move current frame annotation to `_deleted/` |
| `S` | Launch SAM3 tracking |
| `X` | Stop SAM3 tracking |
| `+` / `=` | Zoom in ×1.25 |
| `-` | Zoom out ×1.25 |
| `.` | Reset zoom |
| `Ctrl + scroll` | Zoom centred on cursor |
| `Escape` | Exit Draw/Erase mode, or close the editor |

---

## Dataset visualisation — `labels2video.py`

`labels2video.py` reads an annotated dataset folder and renders all frames into a single MP4 video, with bounding boxes and class names drawn on each frame. Useful for quickly reviewing the quality of an annotation session.

```bash
python labels2video.py \
    --folder /path/to/dataset \
    [--fps   25]
```

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `--folder` | Yes | — | Dataset directory containing `images/` and `labels/` sub-folders. |
| `--fps` | No | `25` | Frame rate of the output video. |

The script writes `output.mp4` directly into `--folder`. Frames that have no corresponding label file are included as-is (no overlay).

Box colours and class name labels are read from `config.py` (`_PALETTE_BGR` and `CLASS_NAMES`), so they stay consistent with the editor.
