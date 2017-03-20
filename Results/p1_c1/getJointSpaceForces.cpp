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
//	-	external forces (left/right GRF).
//
// This function calculates these joint space forces, checks that they satisfy 
// the classical equation of motion, and saves them for later use in an 
// optimization. 
//
// This function supports and requires a single command line argument: the path
// to the directory where the results are to be read in from. 
//
// To do: document some assumptions, i.e. using in tandem with the Matlab 
// inverse model code, for one thing Matlab makes the results folder as a 
// relative path, etc...
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
				  
void writeMatrix(std::ofstream& file_name,
				   double time, 
				   Matrix matrix_object);
				   
void writeMatrixTimeless(std::ofstream& file_name,
						 Matrix matrix_object);
					  
void printForceVector(Vector_<double> vec,
					  std::string description);

int main(int argc, const char * argv[])
{
	// Here we assume that the correct pathname to the results directory is 
	// given. Later in the code when we attempt to open files errors will be 
	// thrown if this is unsuccessful.
	if (argc == 1) {
		std::cout << "Error: require path to results folder as a command line" 
				<< " argument." << std::endl; 
		return 1;
	}
	else if (argc > 2) {
		std::cout << "Error: too many command line arguments." << std::endl;
		return 1;
	}
	
	// Get the OpenSim results directory from the input argument. 
	std::string OSIM_RESULTS = argv[1];
	
	// Given this results directory and using knowledge of the structure of the 
	// Matlab inverse model code, get variables for other key files. 
	std::string MODEL_FILE = OSIM_RESULTS + "/../testing_adjusted.osim";
	std::string STATES = OSIM_RESULTS + "/RRA_states.sto";
	std::string ACCELERATIONS = OSIM_RESULTS + "/RRA_accelerations.sto";
	std::string DYNAMICS = OSIM_RESULTS + "/ID_dynamics.sto";
	std::string REACTION_FORCES = OSIM_RESULTS + "/grf.mot";
	
	// Create a variable for the output results directory.
	std::string JSF_RESULTS = OSIM_RESULTS + "/../jsf";
	
	// Create variable names for the output files. 
	std::string LEFT_APO_JACOBIAN = JSF_RESULTS + "/left_apo_jacobian.txt";
	std::string RIGHT_APO_JACOBIAN = JSF_RESULTS + "/right_apo_jacobian.txt";
	std::string RESIDUAL_FORCE = JSF_RESULTS + "/residual_force.txt";
	std::string INTERNAL_FORCE = JSF_RESULTS + "/net_internal_values.txt";
	
	// Need a 
	bool first_frame = true; 
	
	try {
		
		// Load OpenSim model from file, initialise state and calculate some 
		// dynamic properties. 
		Model osimModel(MODEL_FILE);
		SimTK::State & si  = osimModel.initSystem();
		int n_dofs = osimModel.getMatterSubsystem().getNumMobilities(),
			n_bodies = osimModel.getMatterSubsystem().getNumBodies();
		
		// Create time variable. 
		double time; 
		
		// Load the necessary files from the RRA results (states, 
		// accelerations, forces) and the raw data (grfs).
		std::ifstream states_file(STATES), 
					  accelerations_file(ACCELERATIONS),
					  dynamics_file(DYNAMICS), 
					  grfs_file(REACTION_FORCES);
		
		// Open files for output. 
		std::ofstream leftAPOJacobian_file(LEFT_APO_JACOBIAN), 
					  rightAPOJacobian_file(RIGHT_APO_JACOBIAN), 
					  residualForce_file(RESIDUAL_FORCE), 
					  internalForce_file(INTERNAL_FORCE);

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
		std::cout << "Number of bodies: " << n_bodies << std::endl; 
		std::cout << "Degrees of freedom: " << n_dofs << std::endl; 
		std::cout << "Beginning calculation of system & state properties..." 
				<< std::endl;

		while (true)
		{
			// Dump first entry (time) for each file. Code requires aligned 
			// data inputs so these are the same.
			grfs_file >> time;
			states_file >> time;
			accelerations_file >> time;
			dynamics_file >> time;
			
			if (states_file.eof()) {
				std::cout << "\nReached end of states file." << std::endl;
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
			
			// Calculate joint-space force due to ground reaction forces, and
			// simultaneously calculate the Jacobians to the left and right 
			// APO contact points.
			Vector leftGRFTorques, rightGRFTorques;
			Matrix leftAPOJacobian, rightAPOJacobian;
			
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
			
			// Orthosis COP is COP of external force applied by APO in R/L
			// femur frames. See report for more info on this.
			SimTK::Vec3 orthosisCOP(0);
			
			orthosisCOP[0] = 0;
			orthosisCOP[1] = -0.35;
			orthosisCOP[2] = 0;
		
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
					
				} else if (
					osimModel.getBodySet().get(j).getName() == "femur_r") {
					
					const SimTK::Vec3 orthosisCOP_reference(orthosisCOP);
					
					// Calc right APO Jacobian. 
					osimModel.getMatterSubsystem().
						calcFrameJacobian(si, MobilizedBodyIndex(testingBodies), 
							orthosisCOP_reference, rightAPOJacobian);
					
				} else if (
					osimModel.getBodySet().get(j).getName() == "femur_l") {
					
					const SimTK::Vec3 orthosisCOP_reference(orthosisCOP);
					
					// Calc left APO Jacobian. 
					osimModel.getMatterSubsystem().
						calcFrameJacobian(si, MobilizedBodyIndex(testingBodies), 
							orthosisCOP_reference, leftAPOJacobian);
					
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
			
			if (! first_frame) {
			
				// Write the APO Jacobians to a file.
				writeMatrixTimeless(leftAPOJacobian_file,leftAPOJacobian);
				writeMatrixTimeless(rightAPOJacobian_file,rightAPOJacobian);
				
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
				writeVectorTimeless(residualForce_file, residualForce);
				writeVectorTimeless(internalForce_file, internalForce);
				
				// Can use writeVector or writeMatrix to write a time-indexed 
				// file if I end up needing this. 
				
			} else {
				first_frame = false;
			}
			
			// Output the time of the current state and separate the timesteps
			// visually. Print each joint-space vector to the screen. 
			std::cout << "---------------------------------------" << std::endl; 
			std::cout << "Time: " << time << std::endl; 
			printForceVector(dynamics, "net joint torques");
			printForceVector(inertiaTorques, "inertia");
			printForceVector(gravityTorques, "gravity");
			printForceVector(coriolisTorques, "centrifugal effects");
			printForceVector(rightGRFTorques, "right foot contact");
			printForceVector(leftGRFTorques, "left foot contact");
			
			
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

void writeMatrix(std::ofstream& file_name,
					  double time, 
					  Matrix matrix_object)
{  					  
	file_name << time;
	for (int k = 0; k < matrix_object.nrow(); k++) 
	{
		for (int j = 0; j < matrix_object.ncol(); j++) 
		{
			file_name << "\t";
			file_name << matrix_object[k][j];
		}
		file_name << "\n";
	}
}

void writeMatrixTimeless(std::ofstream& file_name,
						 Matrix matrix_object)
{
	for (int k = 0; k < matrix_object.nrow(); k++)
	{
		for (int j = 0; j < matrix_object.ncol(); j++)
		{
			if (! (j == matrix_object.ncol() - 1))
			{
				file_name << matrix_object[k][j];
				file_name << "\t";
			}
			else
			{
				file_name << matrix_object[k][j];
			}
		}
		file_name << "\n";
	}
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
