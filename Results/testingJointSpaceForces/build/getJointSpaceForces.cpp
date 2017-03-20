//==============================================================================
//							getJointSpaceForces.cpp
//
//Code using the OpenSim C++ API to, given the results of an RRA analysis on some OpenSim
//model file and the raw GRF data, calculate the joint space forces comprising the 
//classical equation of motion i.e.
//
//				M(q)q.. + C(q,q.) + g(q) = tau + F,
// 
//From left to right, we have the joint space forces due to: 
//
//	-	inertia,
// 	-	coriolis & other nonlinear effects,
//	-	gravity,
//	-	net joint moments (human subject + attached exoskeleton),
//	-	external forces (left/right GRF).
//
//This function calculates these joint space forces, checks that they satisfy the classical
//equation of motion, and saves them for later use in an optimization. 
//==============================================================================
//==============================================================================

#include <OpenSim/OpenSim.h>
#include <iostream>
#include <fstream> 
#include <sstream> 
#include <iomanip>

using namespace OpenSim;
using namespace SimTK;

void compose_file(std::ofstream& file_name, int time_step, Vec<5,double> time_array, Vector vector_object, int columnSize);
void compose_jacobian(std::ofstream& file_name, int time_step, Vec<5,double>time_array, Matrix matrix_object, int columnSize, int rowSize );
bool is_digits(const std::string &str);

int main(int argc, const char * argv[])
{
	// Handle command line arguments. If none, set number of timeSteps to 1 (i.e. code runs through one time). If two, check that the provided argument is of the right form
	// (a collection of digits), then convert to integer and set timeSteps. If more than two throw an error. 
	if (argc == 1) {
		int timeSteps = 1; 
	}
	else if (argc == 2) {
		if (is_digits(argv[1])) {
			int timeSteps = std::atoi(argv[1]);
			std::cout << timeSteps << std::endl; 
		} else {
			std::cout << "Error: expected integer as command line argument." << std::endl;
			return 0;
		}
	}
	else if (argc > 2) {
		std::cout << "Error: received more than the maximum number (%i) of command line arguments expected." << std::endl;
		return 0;
	}
	
	try {
		
		// Load OpenSim model from file, initialise state and calculate some dynamic properties. 
		
		Model osimModel("../../testing_adjusted.osim");
		SimTK::State & si  = osimModel.initSystem();
		int n_dofs = osimModel.getMatterSubsystem().getNumMobilities(); 
		int n_bodies = osimModel.getMatterSubsystem().getNumBodies();
		
		// Create time variable. 
		
		Vec<5,double> time; // this needs to be done better 
		
		// Load the necessary files from the RRA results (states, accelerations, forces) and the raw data (grfs).
		
		std::ifstream states("../../states.sto"); 
		std::ifstream accelerations("../../accelerations.sto");
		std::ifstream forces("../../forces.sto");
		std::ifstream grfs("../../grf.mot");
		
		/* I WANT TO FIX THIS EVENTUALLY SO IT'S NOT LIKE THE ABOVE, BUT I'LL DO IT AFTER. 
		
		std::vector<std::string> inputFileNames {"states.sto", "accelerations.sto", "forces.sto", "grf.mot"};
		std::vector<std::ifstream> inputFileStreams(size(inputFileNames));
		
		for (int i=0; i < size(inputFileNames); i++) {
			
		} */
		
		// Open a file for output (testing). 
		
		/*std::vector<std::string> outputFileNames {"left_apo_jacobian", "right_apo_jacobian", "net_y", "net_internal", "subsampled_states"};
		std::vector<std::ofstream> outputFileStreams(size(outputFileNames));
		
		fileStreams[0].open("../../test.txt"); */
		
		std::ofstream subsampled_states, left_apo_jacobian, right_apo_jacobian, net_y, net_internal;
		
		subsampled_states.open ("../../subsampled_states.txt");
		
		left_apo_jacobian.open ("../../left_apo_jacobian.txt");
		right_apo_jacobian.open ("../../right_apo_jacobian.txt");
		
		net_y.open ("../../net_y_values.txt");
		net_internal.open ("../../net_internal_values.txt");
		
		// Gain access to the Simbody matter subsystem. 
		
		// Get some information and print it to the screen. 		
		
		std::cout << "Number of bodies: " << n_bodies << std::endl; 
		std::cout << "Degrees of freedom: " << n_dofs << std::endl; 
		std::cout << "Beginning calculation of system & state properties..." << std::endl;
		
		// Begin loop over timesteps.

		double * state = new double[2*n_dofs];
			
		const int expectedGRFSize = 18;	
			
		Vector_<double> acceleration(n_dofs); // In theory the model could not match up to the data files... I should have a check, with these. 
		Vector_<double> force(n_dofs);
		Vec<expectedGRFSize,double> grf;	// How to modularize this/have some sort of check for the number of contacts? 	
		
		for (int i=0; i < 5; i++) { // Upper bound is 2 now for testing, but should be the maximum timestep. 
			
			states >> time[i];
			accelerations >> time[i];
			forces >> time[i];
			grfs >> time[i]; 
			
			// These are the same so this isn't actually changing time, but just need to dump the first entry of each file. 
			// Need to have some sort of check to ensure that they are actually the same. 
		
			
			for (int j = 0; j < expectedGRFSize; j++) {
				grfs >> grf[j]; // save grfs as vector
			} 
			
			for (int j = 0; j < n_dofs; j++) {
				forces >> force[j];
				// Should have a method here which checks the ordering to make sure all the files match up. 
			}
			
			for (int j = 0; j < n_dofs; j++) {
				accelerations >> acceleration[j];
				if ((j < 3) || (j > 5)){ // Again, can maybe generalise this by storing the labels and checking these. 
					acceleration[j] = acceleration[j]*(std::atan(1)*4)/180.0; // Have to remember to turn the right quantities in to radians. 
				}
			}
			
			for (int j = 0; j < 2*n_dofs; j++) {
				states >> state[j];
			}
			
			const double * state_pointer = state;
			
			// Reduce the frequency of the force, acceleration and state data to 100Hz (from 1000Hz). 
			// Can have a method here to detect the frame rate of the data sources using the time arrays, ensure they all match, and if not find a common 
			// rate achievable via subsampling. 
			
			for (int j = 0; j < 10; j++) {
				forces.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
				accelerations.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
				states.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
			}
			
			// Output the time of the current state and separate the timesteps visually. 
			
			std::cout << "------------------------------------------------------------------------------------------------------------------------------------------------" << std::endl; 
			std::cout << "Time: " << time[i] << std::endl; 
			
			// All of these output statements can fall in to a single function. 
			
			std::cout << std::endl << "Generalised force due to net APO and joint torques: " << std::endl;
			
			std::cout << "[";
			for (int j=0; j<force.size()-1; j++) {
				std::cout << force[j] << ", ";
			}
			std::cout << force[force.size()-1] << "]" << std::endl; 
		
			// Try to print the mass matrix.

			osimModel.setStateValues(si, state_pointer);
				
			osimModel.updMultibodySystem().realize(si, Stage::Dynamics); // Get access to the system and realize up to the dynamics stage.

			// It is inefficient and unnecessary to compute/print the mass matrix, but the steps for doing so are below. Instead, the better 
			// thing to do is multiply straight away the acceleration and mass matrix together, the output of which is a 23dof generalized
			// force vector. This is the method that is followed.
			
			// SimTK::Matrix MM(n_dofs, n_dofs); // Holder for the mass matrix.
			// osimModel.getMatterSubsystem().calcM(si, MM); // Calculate the system mass matrix at the given state.
			//std::cout << std::endl << "Mass matrix: " << MM;
			
			// Really it would be much easier to optimise this code if rather than having a distinct array for each of the generalised forces they were all stored in 
			// one larger array. Works because they're all the same size vector anyway. Think about fixing this.
			
			Vector inertiaTorques;
			
			const SimTK::Vector acceleration_reference(acceleration);
			
			osimModel.getMatterSubsystem().multiplyByM(si, acceleration_reference, inertiaTorques);
			
			std::cout << std::endl << "Generalised force due to inertia: " << std::endl;
			
			std::cout << "[";
			for (int j=0; j<inertiaTorques.size()-1; j++) {
				std::cout << inertiaTorques[j] << ", ";
			}
			std::cout << inertiaTorques[inertiaTorques.size()-1] << "]" << std::endl;
			
			const Vector_<SpatialVec>& gravityForces = osimModel.getGravityForce().getBodyForces(si);
			
			Vector gravityTorques; 
			
			osimModel.getMatterSubsystem().multiplyBySystemJacobianTranspose(si, gravityForces, gravityTorques);
			
			/*std::cout << std::endl << "Force due to gravity at body origins: " << std::endl;
			
			for (int j=0; j<gravityForces.size(); j++) {
			std::cout << gravityForces[j] << std::endl;
			//std::cout << gravityForces[j](0) << "   " << gravityForces[j](1) << std::endl; 
			}*/
			
			// The above is there mainly to show how to correctly access the gravity forces. The vector gravityForces is a vector of size 18,
			// where the ground is indexed by 0, each element of which is a spatial vector (6D vector), the first three elements of which are 
			// the rotational component and the last 3 components of which are the translational component.
			
			// What I have above is a 6D spatial vector for each body in the model which describes the force experienced at the body origin 
			// (not necessarily the CoM, hence the torque term). What remains is to map these on to generalised forces using Jacobians. 
			
			std::cout << std::endl << "Generalised force due to gravity: " << std::endl; 
			
			std::cout << "[";
			for (int j=0; j<gravityTorques.size()-1; j++) {
				std::cout << gravityTorques[j] << ", "; 
			}
			std::cout << gravityTorques[gravityTorques.size()-1] << "]" << std::endl;
			
			//SimTK::Vector_<SpatialVec> totalCentrifugalForces; // This causes the code to crash. 
			SimTK::Vec<18, SpatialVec> totalCentrifugalForces;
			
			totalCentrifugalForces[0](0) = 0; // Ground 
			totalCentrifugalForces[0](1) = 0;
			
			for (int j=1; j < osimModel.getMatterSubsystem().getNumBodies(); j++) {
				
				const SpatialVec& bodyCentrifugalForces = osimModel.getMatterSubsystem().getTotalCentrifugalForces(si, MobilizedBodyIndex(j));
				
				totalCentrifugalForces[j](0) = bodyCentrifugalForces[0];
				totalCentrifugalForces[j](1) = bodyCentrifugalForces[1];
				
			}
			
			SimTK::Vector_<SpatialVec> totalCentrifugalForces_reference(totalCentrifugalForces);
			
			Vector coriolisTorques; 
			
			osimModel.getMatterSubsystem().multiplyBySystemJacobianTranspose(si, totalCentrifugalForces_reference, coriolisTorques);
			
			std::cout << std::endl << "Generalised force due to centrifugal effects: " << std::endl;
			
			std::cout << "[";
			for (int j=0; j<coriolisTorques.size()-1; j++) {
				std::cout << coriolisTorques[j] << ", ";
			}
			std::cout << coriolisTorques[coriolisTorques.size()-1] << "]" << std::endl;
			
			/*const Array<std::string>& variableNames = osimModel.getStateVariableNames();
			
			std::cout << variableNames.size() << std::endl; 
			
			for (int j=0; j<variableNames.size(); j++) {
				std::cout << variableNames[j] << std::endl;
				std::cout << j << std::endl;
			}*/
			
			// I'm perplexed as to why the above bit of code doesn't work. I create a reference to an array of the filenames. When I try to 
			// print these out within a for loop, the expected output is printed to the screen, but the code crashes upon finishing the loop.
			// For example for what is currently written the code crashes after outputting '53' to the screen. I tried changing the upper 
			// bound for the loop to be variableNames.size() - 1 and this produced the expected effect but still caused a crash, this time 
			// after '52'. I'm going to have to ask Vlad - but he's on holiday. 
		
			SimTK::Vec3 groundRightForce(0), groundRightCOP(0), groundRightMoment(0), rCalcForce(0), rCalcCOP(0), rCalcMoment(0);
			
			SimTK::Vec3 groundLeftForce(0), groundLeftCOP(0), groundLeftMoment(0), lCalcForce(0), lCalcCOP(0), lCalcMoment(0);
			
			SimTK::Vec3 orthosisCOP(0);
			
			// Orthosis COP is the centre of pressure of the external force being applied by the APO. It is the same for the left and right femur, 
			// and it is in the reference frame of the associate femur, hence the constant (0, -0.35, 0). The -0.35 is a somewhat arbitrary first 
			// guess at how far down the APO link is roughly from the hip joint.
			
			// Note we are positioning the 'contact point' internally within the femur, also we are assuming the APO motors lie precisely where the 
			// hip joints are, and there's a straight lever arm going down the femur. More sophisticated model/analysis to eventually be required,
			// but we'll see how this works as a first step. 
			
			orthosisCOP[0] = 0;
			orthosisCOP[1] = -0.35;
			orthosisCOP[2] = 0;

			groundRightForce[0] = grf[0];
			groundRightForce[1] = grf[1];
			groundRightForce[2] = grf[2];
			groundRightCOP[0] = grf[3];
			groundRightCOP[1] = grf[4];
			groundRightCOP[2] = grf[5];
			groundRightMoment[0] = grf[12];
			groundRightMoment[1] = grf[13];
			groundRightMoment[2] = grf[14];
			
			groundLeftForce[0] = grf[6];
			groundLeftForce[1] = grf[7];
			groundLeftForce[2] = grf[8];
			groundLeftCOP[0] = grf[9];
			groundLeftCOP[1] = grf[10];
			groundLeftCOP[2] = grf[11];
			groundLeftMoment[0] = grf[15];
			groundLeftMoment[1] = grf[16];
			groundLeftMoment[2] = grf[17];
			
			Vector leftGRFTorques, rightGRFTorques; 
			Matrix leftAPOJacobian, rightAPOJacobian; 
		
			for (int j=0; j<n_bodies; j++) {
				
				// Assuming here that the j'th body in osimModel.getBodySet() corresponds to the body obtained through getMobilizedBody(MobilizedBodyIndex(j)).
				// This is how I'm going to get the left & right calcaneous for doing the ground contacts. 
				
				const MobilizedBody& testingBodies = osimModel.getMatterSubsystem().getMobilizedBody(MobilizedBodyIndex(j));
				
				if (osimModel.getBodySet().get(j).getName() == "calcn_r") {
					
					osimModel.getSimbodyEngine().transform(si, osimModel.getBodySet().get(0), groundRightForce, osimModel.getBodySet().get(j), rCalcForce); // Transforms a vector. 
					osimModel.getSimbodyEngine().transformPosition(si, osimModel.getBodySet().get(0), groundRightCOP, osimModel.getBodySet().get(j), rCalcCOP); // Transforms a point. 
					osimModel.getSimbodyEngine().transform(si, osimModel.getBodySet().get(0), groundRightMoment, osimModel.getBodySet().get(j), rCalcMoment);
					
					SimTK::SpatialVec rCalcSpatial;
					
					//cubeSpatial[0] = cubeMoment;
					//cubeSpatial[1] = cubeForce;
					
					// OR
					
					rCalcSpatial[0] = groundRightMoment; // I think this is correct as the forces/moments are supposed to be expressed in the ground frame. 
					rCalcSpatial[1] = groundRightForce; 
					
					const SimTK::Vec3 rCalcCOP_reference(rCalcCOP); 
					const SimTK::SpatialVec rCalcSpatial_reference(rCalcSpatial); 
					
					osimModel.getMatterSubsystem().multiplyByFrameJacobianTranspose(si, MobilizedBodyIndex(testingBodies), rCalcCOP_reference, rCalcSpatial_reference, rightGRFTorques);
					
					std::cout << std::endl << "Generalised force due to right foot contact: " << std::endl;
			
					std::cout << "[";
					for (int j=0; j<rightGRFTorques.size()-1; j++) {
						std::cout << rightGRFTorques[j] << ", ";
					}
					std::cout << rightGRFTorques[rightGRFTorques.size()-1] << "]" << std::endl;
					
				} else if (osimModel.getBodySet().get(j).getName() == "calcn_l") {
					
					osimModel.getSimbodyEngine().transform(si, osimModel.getBodySet().get(0), groundLeftForce, osimModel.getBodySet().get(j), lCalcForce); // Transforms a vector. 
					osimModel.getSimbodyEngine().transformPosition(si, osimModel.getBodySet().get(0), groundLeftCOP, osimModel.getBodySet().get(j), lCalcCOP); // Transforms a point. 
					osimModel.getSimbodyEngine().transform(si, osimModel.getBodySet().get(0), groundLeftMoment, osimModel.getBodySet().get(j), lCalcMoment);
					
					SimTK::SpatialVec lCalcSpatial;
					
					//cubeSpatial[0] = cubeMoment;
					//cubeSpatial[1] = cubeForce;
					
					// OR
					
					lCalcSpatial[0] = groundLeftMoment; // I think this is correct as the forces/moments are supposed to be expressed in the ground frame. 
					lCalcSpatial[1] = groundLeftForce; // So I think this means the orientation should be in ground (fy up etc, as opposed to at the angle of the body).
					
					const SimTK::Vec3 lCalcCOP_reference(lCalcCOP); 
					const SimTK::SpatialVec lCalcSpatial_reference(lCalcSpatial); 
					
					osimModel.getMatterSubsystem().multiplyByFrameJacobianTranspose(si, MobilizedBodyIndex(testingBodies), lCalcCOP_reference, lCalcSpatial_reference, leftGRFTorques);
					
					std::cout << std::endl << "Generalised force due to left foot contact: " << std::endl;
			
					std::cout << "[";
					for (int j=0; j<leftGRFTorques.size()-1; j++) {
						std::cout << leftGRFTorques[j] << ", ";
					}
					std::cout << leftGRFTorques[leftGRFTorques.size()-1] << "]" << std::endl;
					
				} else if (osimModel.getBodySet().get(j).getName() == "femur_r") {
					
					const SimTK::Vec3 orthosisCOP_reference(orthosisCOP);
					
					osimModel.getMatterSubsystem().calcFrameJacobian(si, MobilizedBodyIndex(testingBodies), orthosisCOP_reference, rightAPOJacobian);
					
				} else if (osimModel.getBodySet().get(j).getName() == "femur_l") {
					
					const SimTK::Vec3 orthosisCOP_reference(orthosisCOP);
					
					osimModel.getMatterSubsystem().calcFrameJacobian(si, MobilizedBodyIndex(testingBodies), orthosisCOP_reference, leftAPOJacobian);
					
				}
				
			}
			
			if (i != 0) { // Basically, stop the first time-step being saved as it is odd, come back to this to see why.
				
				subsampled_states << time[i];
				for (int j = 0; j < 2*n_dofs; j++) {
					subsampled_states << "\t";
					subsampled_states << state[j];
				}
				subsampled_states << "\n";
				 
				compose_jacobian(left_apo_jacobian, i, time, leftAPOJacobian, n_dofs, 6);
				compose_jacobian(right_apo_jacobian, i, time, rightAPOJacobian, n_dofs, 6);
				
				net_y << time[i];
				net_internal << time[i];
				for (int j=0; j < n_dofs; j++) {
					net_y << "\t";
					net_internal << "\t";
					net_y << gravityTorques[j] - inertiaTorques[j] +force[j] - coriolisTorques[j] + rightGRFTorques[j] + leftGRFTorques[j];
					net_internal << -gravityTorques[j] + inertiaTorques[j] + coriolisTorques[j] - rightGRFTorques[j] - leftGRFTorques[j];
				}
				net_y << "\n"; 
				net_internal << "\n";
				
			}
			
		}
		
		delete [] state;
		
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

    //std::cout << "OpenSim example completed successfully.\n";
	// I NEED TO CLOSE ALL OF MY FILES!
	
	return 0;
}

void compose_jacobian(std::ofstream& file_name, int time_step, Vec<5,double>time_array, Matrix matrix_object, int columnSize, int rowSize ) { // should make ints local 
	
	file_name << time_array[time_step];
	for (int k = 0; k < rowSize; k++) {
		for (int j = 0; j < columnSize; j++) {
			file_name << "\t";
			file_name << matrix_object[k][j];
		}
		file_name << "\n";
	}
}

void compose_file(std::ofstream& file_name, int time_step, Vec<5,double>time_array, Vector vector_object, int columnSize) { // dont need time array just give the double actual time
	
	file_name << time_array[time_step];
	for (int j = 0; j < columnSize; j++) {
		file_name << "\t";
		file_name << vector_object[j];
	}
	file_name << "\n";
	
}

// Checks a const string (or const char *?) to see if each element is a digit (0-9). If so returns true, otherwise false.  
bool is_digits(const std::string &str)
{
    return std::all_of(str.begin(), str.end(), ::isdigit);
}
	
