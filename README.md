# Flare Timing

**Flare Timing** will show a pilot's competition score in detail but is currently a work in progress.

The official scoring program for hang gliding and paragliding competitions is [FS](http://fs.fai.org/). Its principal output for a competition task is an html table of pilot scores. In addition to the day's scores, there are columns in this table for the time on course, the distance flown and for the breakdown of the scored points among distance points, lead points, time points and arrival points.

Looking for examples? There is a good archive of past Forbes Flatlands [competition results](http://www.forbesflatlands.com/results/past-results), for instance results for [task 1](https://www.forbesflatlands.com/results-show?id_results=7&db=results2013&class=results_open) of the 19th World Hang Gliding Champs.

Commission Internationale de Vol Libre (CIVL - Hang Gliding and Paragliding Commission) is an Air Sport Commission (ASC) of the Fédération Internationale Aéronautique (FAI). CIVL produce FS. It is the work of paid and volunteer developers.

The scoring method is [well documented](http://fs.fai.org/trac/wiki/ScoringFormulas). Principal documents are;

* [Sporting Code Section 7A - Annex GAP](https://www.fai.org/sites/default/files/documents/sporting_code_s7a-xc-civl_gap_annex_1.pdf) - The definitive guide produced and maintained by CIVL.
* [GAP 2002](http://fs.fai.org/trac/raw-attachment/wiki/ScoringFormulas/GAP02_en.pdf) - A much shorter and less formal guide that is a good first read to gain an understanding of why GAP is needed and how it works.

**Flare Timing** provides a reference implementation of GAP and shows the working of how a pilot's score is calculated.

## Usage

See the separate discussion of [building](BUILDING.md) and [testing](TESTING.md).

FSDB is the database of FS and is an XML format for inputs, working and outputs of scoring. To host a **Flare Timing** web site, start with an FSDB file and relative tracklog files on disk and run a pipeline of command line programs to produce the data to display then host the web services and web app.

1. Extract the inputs with [`extract-task`](flare-timing/prod-apps/extract-task).  
Reads `.fsdb`. Writes `.comp-input.yaml`.
2. Trace the shortest path to fly a task with [`task-length`](flare-timing/prod-apps/task-length).  
Reads `.comp-input.yaml`. Writes `.task-length.yaml`.
3. Find pairs of fixes crossing over zones with [`cross-zone`](flare-timing/prod-apps/cross-zone).  
Reads `.comp-input.yaml` and `.kml`. Writes `.cross-zone.yaml`.
4. Interpolate between crossing fixes for the time and place where a track tags a zone with [`tag-zone`](flare-timing/prod-apps/tag-zone).  
Reads `.cross-zone.yaml`. Writes `.tag-zone.yaml`.
5. Time align the distance to goal for each fix in the speed section with [`align-time`](flare-timing/prod-apps/align-time).  
Reads `.comp-input.yaml` and `.tag-zone.yaml`. Writes `n.align-time.csv`, where `n` is the task number.
6. Filter fixes that get further from goal with `filter-time`.  
Reads `n.align-time.csv`. Writes `n.filter-time.yaml`.
7. Find the nearest a track came to missing the next zone on course with [`near-miss`](flare-timing/prod-apps/near-miss).  
Reads `n.filter-time.csv`. Writes `.near-miss.yaml`.
8. Transpose the table `sort-distance`.  
Reads `n.filter-time.csv`. Writes `n.sort-distance.yaml`.
9. Filter fixes that get further from goal leading area with `leading-area`.  
Reads `n.sort-distance.csv`. Writes `.leading-area.yaml`.
10. Mask the competition task over the tracklogs with [`mask-track`](flare-timing/prod-apps/mask-track).  
Reads `.comp-input.yaml`, `.tag-zone` and `.near-miss`. Writes `.mask-track.yaml`.
11. Score the competition with `gap-point`.  
Reads `.comp-input.yaml`. Writes `.gap-point.yaml`.
12. Start the [`server`](flare-timing/prod-apps/app-serve) hosting the web services.
13. Start the [`dev server`](flare-timing/view) or otherwise host the web app.
