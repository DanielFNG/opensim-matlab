//==============================================================================
//							getJointSpaceForces.cpp
//
// Code using the OpenSim C++ API to, given the results of an RRA analysis on 
// some OpenSim model file and the raw GRF data, calculate the joint space
// forces comprising the classical equation of motion i.e.
//
//						M(q)q.. + C(q,q.) + g(q) = tau + F,
// 
// From left to right, we have the joint space forces due to: 
//
//	-	inertia,
// 	-	coriolis & other nonlinear effects,
//	-	gravity,
//	-	net joint moments (human subject + attached exoskeleton),
//	-	external forces (e.g. left/right GRF).
//
// This function supports and REQUIRES five command line arguments: the absolute
// paths to a set of input files. These files are as follows:
//
// (1) The model file;
// (2) The external forces data file;
// (3) The states file from an RRA analysis of an OpenSimTrial;
// (4) The accelerations file from an RRA analysis of an OpenSimTrial;
// (5) The inverse dynamics file from an ID analysis of a kinematics file,
//	   which itself resulted from an OpenSimTrial. 
//
// care should be taken to precisely match the order of these input arguments.
//
// There is an additional REQUIRED (6) command line argument which is the 
// absolute path to a directory where the results are to be saved. The results 
// are saved as tab delimited .txt files with some nominal filenames which are 
// similar to those listed above, but with underscores instead of spaces where 
// relevant (i.e. net_joint_moments.txt). There are two additional output files:
//
// A) calculated net joint moments 
// B) discrepancy
//
// A) is similar to the net joint moments, but rather than being calculated from 
// the ID process of an OpenSim trial, it is calculated by an appropriate 
// summation of the other joint-space forces.
//
// B) is the difference between the net joint moments measured from ID and A) 
// above. B) is used to make sure that the calculation of joint-space forces 
// was sufficiently accurate. THIS SHOULD BE EXACT, MY CURRENT THEORY FOR WHY 
// IT ISN'T IS THE OFFSET IN TIME BETWEEN MOTION DATA AND EXTERNAL FORCES. 
// OPENSIM DOES SOME SORT OF FITTING TO GET THESE AT THE SAME TIME, WHEREAS 
// I WORK WITH DISCRETE TIMESTEPS, WHICH INTRODUCES DISCREPANCIES. SUPPORT FOR 
// THIS THEORY IS THAT B) HAS BEEN MUCH WORSE IN CASES WHERE THERE HAVE BEEN 
// DUPLICATE OR MISSING GRF TIMESTEPS. 
//
// There should be a method in Matlab to read in this discrepancy file and 
// analyse whether this script has completed accurate enough. 
//
// Finally, an OPTIONAL (7) command line argument should be a boolean. If true 
// this sets the verbose keyword which causes the calculation of the joint-space
// forces to be printed. This can be useful for debugging. 
//==============================================================================
//==============================================================================

#include <OpenSim/OpenSim.h>
#include <iostream>
#include <fstream> 
#include <sstream> 
#include <iomanip>

using namespace OpenSim;
using namespace SimTK;

void writeVector(std::ofstream& file_name,
				  double time, 
				  Vector vector_object);
				  
void writeVectorTimeless(std::ofstream& file_name,
						 Vector vector_object);
					  
void printForceVector(Vector_<double> vec,
					  std::string description);

int main(int argc, const char * argv[])
{
	// Handle command line arguments. Check that we have neither too little nor
	// too many. Check that if the optional argument is given, that it's a
	// boolean.
	bool print_info;
	if (argc < 7) {
		std::cout << "Error: too few command line arguments. See comments at" 
				<< " top of file for the correct number and order of input" 
				<< " arguments." << std::endl; 
		return 1;
	} else if (argc > 8) {
		std::cout << "Error: too many command line arguments. See comments at"
				<< " top of file for the correct number and order of input"
				<< " arguments." << std::endl;
		return 1;
	} else if (argc == 8) {
		if (! ((atoi(argv[7]) == 0) || (atoi(argv[7]) == 1))) {
			std::cout << "Error: 7th command line argument, if given, has to be"
					<< " boolean." << std::endl;
			return 1;
		}
		print_info = (atoi(argv[7]) != 0);
		// Convert the int (1 or 0) argv[7] to bool type. 
	}
	std::string model_file = argv[1], ext_path = argv[2], 
		states_path = argv[3], accelerations_path = argv[4],
		id_path = argv[5], results_directory = argv[6];
		
	std::cout << id_path << std::endl;
	
	// Create variable names for the output files. 
	std::string inertia_force = results_directory + "/inertia.txt";
	std::string coriolis_force = results_directory + "/coriolis.txt";
	std::string gravity_force = results_directory + "/gravity.txt";
	std::string external_force = results_directory + "/external.txt";
	std::string actuation_force = results_directory + "/actuation.txt";
	std::string residual_force = results_directory + "/residual.txt";
	std::string internal_force = results_directory + "/internal.txt";
	
	try {
		
		// Load OpenSim model from file, initialise state and calculate some 
		// dynamic properties. 
		Model osimModel(model_file);
		SimTK::State & si  = osimModel.initSystem();
		int n_dofs = osimModel.getMatterSubsystem().getNumMobilities(),
			n_bodies = osimModel.getMatterSubsystem().getNumBodies();
		
		// Create time variable. 
		double time; 
		
		// Load the necessary files from the RRA results (states, 
		// accelerations, forces) and the raw data (grfs).
		std::ifstream states_file(states_path), 
					  accelerations_file(accelerations_path),
					  dynamics_file(id_path), 
					  grfs_file(ext_path);
		
		// Open files for output. 
		std::ofstream inertia_force_file(inertia_force),
					  coriolis_force_file(coriolis_force),
					  gravity_force_file(gravity_force),
					  external_force_file(external_force),
					  actuation_force_file(actuation_force),
					  residual_force_file(residual_force), 
					  internal_force_file(internal_force);

		std::cout << dynamics_file.is_open() << std::endl;
					  
		// Create array for states.
		// Require double array for API compatability.
		double * states = new double[2*n_dofs];
		
		// Create vectors for RRA accelerations and ID dynamics data.
		Vector_<double> accelerations(n_dofs), dynamics(n_dofs);
		
		// Create vector for grf readings. 
		// Assume 18 channels from treadmill i.e. specific to our case. 
		// Given this assumption we don't need a variable size vector. 
		const int expectedGRFSize = 18;
		Vec<expectedGRFSize,double> grfs;
		
		// Output system model info and begin calculations.
		if (print_info) 
		{
			std::cout << "Number of bodies: " << n_bodies << std::endl; 
			std::cout << "Degrees of freedom: " << n_dofs << std::endl; 
			std::cout << "Beginning calculation of system & state properties..." 
					<< std::endl;
		}

		while (true)
		{
			// Dump first entry (time) for each file. Code requires aligned 
			// data inputs so check this. 
			grfs_file >> time;
			double checktime = time; 
			states_file >> time;
			checktime += time;
			accelerations_file >> time;
			checktime += time;
			dynamics_file >> time;
			checktime += time; 
			
			/* if (checktime != time*4.0)
			{
				std::cout << "Error: input files not properly time-aligned."
					<< std::endl;
				return 1;
			} */
			
			if (states_file.eof()) {
				if (print_info) 
				{
					std::cout << "\nReached end of states file." << std::endl;
				}
				break;
			}
			
			// Save data from input files as vectors. 
			for (int j = 0; j < expectedGRFSize; j++) {
				grfs_file >> grfs[j];
			}
			for (int j = 0; j < 2*n_dofs; j++) {
				if (j < n_dofs) {
					dynamics_file >> dynamics[j];
					accelerations_file >> accelerations[j];
					if ((j < 3) || (j > 5)) {
						// Convert accelerations to radians from degrees. The 
						// states file below is already in radians so no need.
						accelerations[j] = accelerations[j] 
										   * (std::atan(1)*4)/180.0;
					}
					states_file >> states[j];
				} else {
					states_file >> states[j];
				}
			}
			/* Some problems: no check for ordering to make sure what's being 
			   read in is in the right order. Could potentially store the 
			   labels and do a check on these. Procedure we use at the moment 
			   produces files with the correct ordering. */ 
		
			// Set the state of the model from the current state as read in 
			// from input datafiles. Realize the simulation up to the 
			// dynamics stage (see Simbody documentation).
			const double * constStatePointer = states;
			osimModel.setStateValues(si, constStatePointer);
			osimModel.updMultibodySystem().realize(si, Stage::Dynamics); 
			
			// Calculate joint-space force due to inertia. 
			Vector inertiaTorques; 
			const SimTK::Vector acceleration_reference(accelerations);
			osimModel.getMatterSubsystem().multiplyByM(si, 
													   acceleration_reference,
													   inertiaTorques);
			
			// Calculate joint-space force due to gravity.
			Vector gravityTorques;
			const Vector_<SpatialVec>& gravityForces = 
					osimModel.getGravityForce().getBodyForces(si);
			osimModel.getMatterSubsystem().
					multiplyBySystemJacobianTranspose(si, 
													  gravityForces, 
													  gravityTorques);
			
			// Calculate joint-space force due to non-linear effects.
			Vector coriolisTorques;
			SimTK::Vec<18, SpatialVec> totalCentrifugalForces;
			totalCentrifugalForces[0](0) = 0; // Ground 
			totalCentrifugalForces[0](1) = 0;
			for (int j=1; j < n_bodies; j++) {
				const SpatialVec& bodyCentrifugalForces = 
					osimModel.getMatterSubsystem().
					getTotalCentrifugalForces(si, MobilizedBodyIndex(j));
				totalCentrifugalForces[j](0) = bodyCentrifugalForces[0];
				totalCentrifugalForces[j](1) = bodyCentrifugalForces[1];
			}
			SimTK::Vector_<SpatialVec> totalCentrifugalForces_reference(
					totalCentrifugalForces);
			osimModel.getMatterSubsystem().multiplyBySystemJacobianTranspose(
					si, totalCentrifugalForces_reference, coriolisTorques);
			
			// Calculate joint-space force due to ground reaction forces.
			Vector leftGRFTorques, rightGRFTorques;
			
			// Variables for the forces, moments and centres of pressure 
			// for each foot reaction force. 
			SimTK::Vec3 groundRightForce(0), groundRightCOP(0), 
						groundRightMoment(0), rCalcCOP(0),
						groundLeftForce(0), groundLeftCOP(0), 
						groundLeftMoment(0), lCalcCOP(0);
			
			// Assign values to the vectors from input data. 
			for (int j = 0; j < 3; j++) {
				groundRightForce[j] = grfs[j];
				groundRightCOP[j] = grfs[j+3];
				groundRightMoment[j] = grfs[j+12];
				groundLeftForce[j] = grfs[j+6];
				groundLeftCOP[j] = grfs[j+9];
				groundLeftMoment[j] = grfs[j+15];
			}
		
			for (int j=0; j<n_bodies; j++) {
				
				// Assuming here that the j'th body in osimModel.getBodySet() 
				// corresponds to the body obtained through 
				// getMobilizedBody(MobilizedBodyIndex(j)). This is how I'm 
				// going to get the left & right calcaneous for doing the 
				// ground contacts. 
				const MobilizedBody& testingBodies = 
						osimModel.getMatterSubsystem().
							getMobilizedBody(MobilizedBodyIndex(j));
				
				if (osimModel.getBodySet().get(j).getName() == "calcn_r") {
					// Get spatial force on calcn_r in ground frame. 
					SimTK::SpatialVec rCalcSpatial;
					rCalcSpatial[0] = groundRightMoment;  
					rCalcSpatial[1] = groundRightForce;
					// I think this is correct as the forces/moments are 
					// supposed to be expressed in the ground frame.
					
					// Transform COP to calcn_r frame.
					// Note this fucntion is for transforming POINTS only.
					// There is a partner function for transforming vectors. 
					osimModel.getSimbodyEngine().
						transformPosition(
							si, osimModel.getBodySet().get(0), groundRightCOP, 
							osimModel.getBodySet().get(j), rCalcCOP); 
					
					// Get references.
					const SimTK::Vec3 rCalcCOP_reference(rCalcCOP); 
					const SimTK::SpatialVec rCalcSpatial_reference(rCalcSpatial);

					// Calc joint-space force. 
					osimModel.getMatterSubsystem().
						multiplyByFrameJacobianTranspose(
							si, MobilizedBodyIndex(testingBodies), 
							rCalcCOP_reference, rCalcSpatial_reference, 
							rightGRFTorques);
					
				} else if (
					osimModel.getBodySet().get(j).getName() == "calcn_l") {
					// Get spatial force on calcn_l in ground frame. 
					SimTK::SpatialVec lCalcSpatial;
					lCalcSpatial[0] = groundLeftMoment;  
					lCalcSpatial[1] = groundLeftForce;
					
					// Transform COP to calcn_l frame.
					osimModel.getSimbodyEngine().
						transformPosition(si, osimModel.getBodySet().get(0), 
							groundLeftCOP, osimModel.getBodySet().get(j), 
							lCalcCOP); 
		
					// Get references. 
					const SimTK::Vec3 lCalcCOP_reference(lCalcCOP); 
					const SimTK::SpatialVec 
							lCalcSpatial_reference(lCalcSpatial); 
					
					// Calc joint-space forces.
					osimModel.getMatterSubsystem().
							multiplyByFrameJacobianTranspose(
									si, MobilizedBodyIndex(testingBodies), 
									lCalcCOP_reference, lCalcSpatial_reference, 
									leftGRFTorques);
					
				}
			}
			/* Above, I transform the COP measured by the treadmill on to the 
			   frame of the corresponding bodies, but not the forces measured
			   by the treadmill. This is because the FrameJacobian functions in 
			   OpenSim require the forces 'measured in the ground frame'. I've 
			   interpreted this to mean what I've implemented above. I did try 
			   transforming them on to the femur frames, and the difference was
			   minimal, but if anything results were better for the current 
			   implementation. But I'm not 100% sure on the correctness of this.
			*/
			
			// Write the various components to a file.
			writeVector(inertia_force_file, time, inertiaTorques);
			writeVector(coriolis_force_file, time, coriolisTorques);
			writeVector(gravity_force_file, time, gravityTorques);
			writeVector(external_force_file, time,
								rightGRFTorques + leftGRFTorques);
			writeVector(actuation_force_file, time, dynamics);
				
			// Write the residual forces and internal forces (almost 
			// identical to net joint torques but with a slighty 
			// discrepancy, a.k.a residual forces) to file.
			Vector residualForce, internalForce; 
			residualForce = gravityTorques - inertiaTorques + dynamics 
							- coriolisTorques + rightGRFTorques 
							+ leftGRFTorques;
			internalForce = inertiaTorques - gravityTorques 
							+ coriolisTorques - rightGRFTorques 
							- leftGRFTorques;
			writeVector(residual_force_file, time, residualForce);
			writeVector(internal_force_file, time, internalForce);
				
			// Can use writeVector or writeMatrix to write a time-indexed 
			// file if I end up needing this. 
			
			if (print_info) 
			{
				// Output the time of the current state and separate the 
				// timesteps visually. Print each joint-space vector to the 
				// screen. 
				std::cout << "---------------------------------------" 
					<< std::endl; 
				std::cout << model_file << std::endl;
				std::cout << states_path << std::endl;
				std::cout << "Time: " << time << std::endl; 
				printForceVector(dynamics, "net joint torques");
				printForceVector(inertiaTorques, "inertia");
				printForceVector(gravityTorques, "gravity");
				printForceVector(coriolisTorques, "centrifugal effects");
				printForceVector(rightGRFTorques, "right foot contact");
				printForceVector(leftGRFTorques, "left foot contact");
			}
		}
		
		delete [] states;
		
	}
    catch (OpenSim::Exception ex)
    {
        std::cout << ex.getMessage() << std::endl;
        return 1;
    }
    catch (std::exception ex)
    {
        std::cout << ex.what() << std::endl;
        return 1;
    }
    catch (...)
    {
        std::cout << "UNRECOGNIZED EXCEPTION" << std::endl;
        return 1;
    }

	// Report successful execution. Still need to check residual forces are 
	// low enough. 
    std::cout << std::endl << "Successfully completed execution." << std::endl;
	std::cout << "Now check the residual forces!" << std::endl;
	
	return 0;
}
						
void writeVector(std::ofstream& file_name,
				  double time, 
				  Vector vector_object)
{ 	
	file_name << time;
	for (int j = 0; j < vector_object.size(); j++) 
	{
		file_name << "\t";
		file_name << vector_object[j];
	}
	file_name << "\n";
	
}

void writeVectorTimeless(std::ofstream& file_name,
						 Vector vector_object)
{
	for (int j = 0; j < vector_object.size(); j++)
	{
		if (! (j == vector_object.size() - 1))
		{
			file_name << vector_object[j];
			file_name << "\t";
		}
		else {
			file_name << vector_object[j];
		}
	}
	file_name << "\n"; 
}

void printForceVector(Vector_<double> vec,
					  std::string description)
{
	std::cout << std::endl << "Joint-space force due to " + description + ":"
			<< std::endl;

	std::cout << "[";
	for (int j=0; j < vec.size() - 1; j++)
	{
		std::cout << vec[j] << ", ";
	}
	std::cout << vec[vec.size()-1] << "]" << std::endl;
}
