The [latest
version](https://github.com/BlockScope/flare-timing/blob/master/app-view/changelog.md)
of this changelog.

# Validity Compared
## app-view-0.21

* Compare task validities side-by-side with those of FS.
* Show the optimal task route from FS on the map.
* Compare optimal task route from FS with those of FS in the Geo table.
* Show the extra distance from glide above goal in the score distance table.
* Compare reach and effort with linear and difficulty from FS in the score
  distance table, in the tables beside the reach and effort plots.
* Handle glitches in the ordering `*.igc` file B record times. Time is meant to
  only increment during the day as fixes are logged. Discard times going
  backward less than an hour and roll over the day when the time goes backwards
  more than that. There's no rule in the GAP document about this but that is
  what FS does.
* Exclude zone crossings that fall outside opening times of the zones.
* Workout task difficulty using relative difficulty from every chunk of the
  task, not just those where a pilot has landed.
* Add score tables for effort, speed, time and arrival. In these, sort the rows
  by descreasing order of the relevant points.
* Include the pilot race number with the pilot in each ###-Pilot column of
  tables.
* Enlarge the split plot.
* Squish and stretch the leading plot to make room for the width of the
  associated table.
* Switch to using the B612 font, designed for use in aircraft cockpit screens.
* Add fs-effort, a command line tool for extracting the landings, chunking and
  relative difficulties from a competition `*.fsdb`.
* Show two more decimal places when point difference is +0.0 or -0.0.
* Clean and trim elements and attributes of the `*.fsdb` before use with
  `fs-filter`, a new command line app that writes `*.clean-fsdb.xml` and
  `*.trim-fsdb.xml`. The cleaned file has sensitive information removed that
  would allow its publication. The trimmed file is the minimal set required by
  flare-timing, taking some data as inputs for scoring and other data for
  comparisons of the scores.

# Stopped Validity and Bonus Reach
## app-view-0.20

* Only consider crossings that are exiting exit zones and entering entry zones.
* Compare arrival fractions between flare-timing and FS.
* Show the working for weight calculations next to the split plot.
* For paragliding, when the goal ratio is zero use a tenth of the distance
  ratio for the leading weight.
* Show the stopped task validity.
* Add plots for launch, distance and time validity.
* Add a series of three plots for stop validity relative to mean reach, the
  spread of reach and the number of pilots landed before the task is stopped.
* Peg the data frame for each pilot's track to the scored time window for
  stopped tasks.
* When the task is stopped, add a bonus distance to reach. Glide from the
  altitude above goal to the altitude of goal for each fix of the track,
  picking the shifted fix that is now closest to goal as the point reached.

# Making a Line Goal
## app-view-0.19

* Sample line goals as semicircles when figuring out the optimal path.
* Sort and rename the base layers of the map to:

        Task
        Path (spherical)
        Path (ellipsoid)
        Path (planar)
        Race (spherical subset of path)
        Race (ellipsoid subset of path)
        Race (spherical subset of waypoints)
        Race (ellipsoid subset of waypoints)
* Detect crossings of line goals.
* Show the list of tasks even when task lengths have not been computed.
* Show the task name in the list of tasks.

# Interpolate Zone Tagging
## app-view-0.18

* Find that GAP and FS use different equations for working out the speed
  fraction and leading fraction. Show the curve of the equation in the GAP
  rules but use the same equation as FS.
* Add a column for leading area in the table alongside the leading point
  distribution graph and compare area, coefficient and fraction with norms.
* When the HH:MM:SS field of IGC B records decrease bump the YYYY-MM-DD.
* Don't apply give to exit cylinders as pilots often fly back into them to take
  a start. They're flown as both entry and exit cylinders.
* When comparing data to norms, if the numbers aren't exactly the same but the
  rounded display of numbers are then display "=" instead.
* Interpolate zone tagging and show pairs of fixes that straddle a zone and the
  tag point as separate markers on the map.
* Draw line goals on the map as semicircles.

# Side-by-Side Score Check
## app-view-0.17

* Parse the `*.fsdb` for scores.
* Add an `Overview | Points | Speed | Distance` set of child tabs beneath the
  `Score` tab. On the **Overview** table display the ranking and total points
  from FS side-by-side with the scores from flare-timing. On the **Points**
  table show side-by-side breakdown of points between FS and flare-timing. On
  the **Speed** table do the same for the components of velocity and on the
  **Distance** table do the same for the components of distance points.

# Effort Plot
## app-view-0.16

* Add a plot for effort.

# Fewer Tabs
## app-view-0.15

* Reduce the number of top level tabs to `Task | Map | Score | Plot | Basis`.
* Select the pilot tracklog for display on the map when fetched.

# Singular Plots
## app-view-0.14

* Default the x-domain when there is one data point to plot.
* Pad the x-domain of the plots relative to the range of the data.
* Add a reach plot.

# Fractional Point Plots
## app-view-0.13

* Add plots for time, arrival and leading point fractions.
* Show the working for task validity.
* Fix errors transcribing the time fraction and leading fraction formulae to code.
* Use color swatches with plot tabs.

# Duplicate Zones and Angle Formats
## app-view-0.12

* Fix a bug showing turnpoints when the first zone starts the speed section.
* When time rolls over in a sequence of IGC B records, bump the date.
* Allow for negative altitudes in IGC B records.
* Allow duplicate zones when working out task distance.
* Detect when pilots jump the gun. The penalty is not yet applied.
* Show the arrival ratio in the legend of the split points plot.
* Show the tiles by default on the map.
* Switch from opentopomap to openstreetmap for the tiles on the map.
* Parse the lat and lng of turnpoints in `*.fsdb` files as ddd or dmm or dms.

# Split of Available Points
## app-view-0.11

* Add a plot of curves showing how the weighting for distance points, for time
  points, for arrival points and for leading points changes in relation to the
  goal ratio. On this show a vertical line showing the weights of the task at
  hand.

# Give a Little
## app-view-0.10

* Score with the give in turnpoint radius.
* Use the last pilot landing time in leading points calculations and allow for
  leading points when no pilots complete the speed section.
* Pilots with no tracks can be assigned speed section times by the scorer and
  thereby get time points and arrival points. Show these assignments.
* Apply percentage and absolute point penalties to pilot scores and show the
  penalty reason.
* Pilots can share arrival position.

# Associate Fixes with Legs
## app-view-0.9

* Better identify which leg each fix belongs to.
* Show the distances to goal in the turnpoints table.
* Show the penalties associated with each pilot.
* Parse when leading and arrival points are off for a task.
* Show the pilots altitude at the score back time for a stopped task.
* Remove duplicate fixes in the tracklog due to ignored sub-second logging.

# Leading Points
## app-view-0.8

* Pilots landing out get their leading points scaled in the same way as pilots
  making goal.
* Fix a bug counting some pilots twice resulting in too large a denominator in
  the goal ratio fraction.
* Parse `FsScoreFormula/@double_leading_weight` as a scaling for leading
  weight, ignoring it if it matches the default for the discipline.
* Score a stopped task.
* Fix a bug adding pilot tracks to the layers control more than once each.
* Show the unscored part of a pilot's track on the map for a stopped task.
* Show when a task was stopped and when it will be scored back to.

# Trackless Pilots
## app-view-0.7

* Parsing `*.fsdb` files for pilots that do not have an associated tracklog
  file that did fly. These pilots will be awarded either the competition
  minimum distance or a another distance decided by the scorer.
* Show when minimum distance was awarded over a lesser flown distance.
* Show which pilots were scored without tracklogs.
* Show that arrival points and difficulty points are not awarded in
  paragliding.
* Pick the most adjacent start gate that opened before the pilot started.
* Show when there are no start gates.
* Show as much as can be shown about tasks that not been flown or scored.
* Show various speed section routes on the map, each calculated differently.
* Add a **Geo** tab showing task distances calculated by various Earth models
  and algorithms.

# Pilot Tracks and Zone Give
## app-view-0.6

* Download and show pilot tracks on the map.
* Show the give or tolerance around turnpoints both in the table an on the map.
* Read and display zone altitude when available.
* Show the shape of the end of the speed section and the shape of goal in the
  turnpoint table.
* Add a settings tab for the competition showing configurations such as the
  Earth model and distance calculation method. Some of these settings are not
  available for extraction from the `*.fsdb` and instead are provided as
  command line options when doing the `extract-input` scoring step.
* Fix a bug in the sampling of zone shapes when setting up the path graph for
  working out the optimal route, #111.
* Fix a bug in showing the legs of the task, #145.

# IGC Parsing, Start Gates and Pilot Status
## app-view-0.5

* Parse the newer `*.igc` **HFDTEDATE:** date header.
* Show pilots that are not yet processed (NYP).
* Show task start gates.
* Show turnpoint open and close times.
* Show competition minimum distance and use this in scoring.
* Show competition score back time.
* Show alternative speed section routes on the map.
* For the point-to-point course line show the turnpoint name but for
  alternative routes show the lat/lng of each waypoint in the marker popup.
* When scoring is incomplete, show the tasks anyway.

# Equal Placings and DNF
## app-view-0.4

* Switch over to using megaparsec when parsing `*.igc` and `*.kml` files.
* Show pilots that did not fly (DNF) with absentees and scores.
* Fix an off-by-one error in equal placings.

```
-- 1,2=,2=,3
++ 1,2=,2=,4
```

# Pan to Zone
## app-view-0.3

Add a toggle button switching between zoom and pan. The map's button group now
has buttons for all zones, not just the speed section zones. The speed section
is indicated with color; green for start and red for stop.

# Zoom to Extent and Zoom to Zone
## app-view-0.2

Only one new feature in this release; a group of buttons above the map for
zooming in on each zone and for zooming to the extents of the task.

# Speed Section Velocity
## app-view-0.1

* Calculate the velocity over the speed section from the speed section distance
* Group headers using colour
* Show legs in the turnpoints table
* Show the optimal route on the map
* Added a layers control to the map
