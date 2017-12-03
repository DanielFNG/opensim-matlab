# ExOpt
ExOpt is a framework for optimisation-based design and control of exoskeletons. It is primarily written in Matlab, on top of the OpenSim Matlab API, but contains code in C++ to use the Simbody dynamics simulator. It is written in an object oriented style.

ExOpt uses a optimisation in dynamics space, utilising a  rigid-body model of a human-exoskeleton system, to calculate the exoskeleton torques required to achieve a certain goal. This goal is typically represented in human joint space, i.e. 'reduce torque at the knee by 50%'. 

Currently, motion and force data for the task being undertaken is a mandatory requirement, as well as a human-exoskeleton model and a force model which translates exoskeleton motor torques in to applied forces. More information on each of these components is available in [Examples](#Examples). 

The optimisation being solved is as follows:

# Working Functionality
An idea of the functionality currently offered by ExOpt is as follows:
  * Read in and perform operations on OpenSim data using supported file types (.mot, .sto, .trc etc).
  * Process motion capture and force data using OpenSim tools i.e. inverse kinematics, inverse dynamics, RRA. This functionality is present in the default OpenSim Maltab API, but here it is implemented to allow simple programmatic calls so as to be used within the rest of the code. There are also scripts for processing data in batches, subject to a suitable file structure of data.
  * Converting from exoskeleton motor torques to forces and vice versa. Provides an easy method for applying these forces in OpenSim. 
  * Use optimisation to calculate the exoskeleton controls, as expressed mathematically above. 

Currently, exoskeleton controls can only be calculated offline. A real-time or quasi-real-time implementation is currently in progress.  

By including the position of the exoskeleton attachment points (i.e. straps or cuffs) as a hyper-parameter in the optimisation, ExOpt can also be used to inform the design of exoskeleton, or the configuration of those exoskeletons which offer adjustable cuff positions (e.g. XoR2). This has not yet been implemented.  

# The Framework
Given access to a human subject with some injury or disability, and an adjustable exoskeleton, an idea of how the ExOpt framework may be applied is as follows.
  * A desired is constructed to offset the difficulties faced by the patient when walking (i.e. more/less torque at a combination of lower body joints).
  * A musculoskeletal model is created and scaled to closely match the human subject. 
  * An accurate exoskeleton model is programmatically constrained to this model. 
  * Motion capture and force data are collected while the subject carries out a task. 
  * The optimisation is run offline to determine a suitable set of exoskeleton cuff positions for the given task.
  * The controller is run in real-time or quasi real-time to calculate the exoskeleton torques which should be applied to complete the task while minimising the difference between the observed human torques and the desired human torques, i.e. achieve the desired as best as possible. 

# Requirements
* OpenSim v3.3 (*other versions may work, but none have been tested*), installed and configured for [scripting with Matlab](http://simtk-confluence.stanford.edu:8080/display/OpenSim/Scripting+with+Matlab).
ExOpt also makes use of the external libraries rapidXML and qpOASES, for interpreting XML files in C++ and performing optimisation, respectively, but these are installed and setup automatically with ExOpt. 

# Installation 
Navigate to the exopt/Setup folder and run the configureExopt.m script. This will attempt to create or append to the startup.m file, as well as add the necessary directories to the Matlab path.

# Examples
Work in progress. 
# Unit testing. 

Work in progress.

