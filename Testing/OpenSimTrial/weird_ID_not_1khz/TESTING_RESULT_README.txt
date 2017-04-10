The result of this testing showed that it is important to have a perfect 1khz framerate of input data
(RRA) if you want the ID to also be at 1khz. Otherwise OpenSim detects the frequency as being lower,
and so the output is not at 1khz (rather 600Hz from what I'd seen).

This is not a problem as fitting RRA data in to an RRAData object does this automatically, but I hadn't
done that in this one case. Therefore, the RRA output files MUST!! be fit to an RRA data object, and then
re-written for use in OpenSim tools!