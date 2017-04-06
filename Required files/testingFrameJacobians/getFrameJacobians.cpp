//==============================================================================
//							getFrameJacobians.cpp
//
// Code using the OpenSim C++ API to calculate the frame Jacobians (see 
// SimbodyMatterSubsystem API documentation) for a set of points on the model.
//
// The inputs are: 
// 					- a musculoskeletal model 
// 					- a time-indexed trajectory of states 
// 					- a set of tuples of the form (3D point, body frame) 
//					  where 3D point denotes a 3D point on the model expressed
//					  in the given body frame 
//
// Eventually I want to MEX this function so it will return something which I 
// can convert in to a Data object of Jacobians. However, for the time being 
// it prints the results to a file which I then read in. Therefore, it also 
// requires a directory in which to print the output file. 
//
// This function supports and REQUIRES three command line arguments: the 
// absolute paths to a set of input files. These files are as follows:
//
// (1) The model file;
// (2) The states file from an RRA analysis of an OpenSimTrial;
// (3) A description of the points for which frame Jacobians are sought. For now
//	   the only way to input this is by using a setup file in xml format. Need
//	   documentation on this. 
//
// care should be taken to precisely match the order of these input arguments.
//
// There is an additional REQUIRED command line argument which is the absolute 
// path to a directory where the results are to be saved (4). The results are 
// saved as tab delimited .txt files with filenames which are derived from the 
// xml setup file. 
//==============================================================================
//==============================================================================

#include <OpenSim/OpenSim.h>
#include <iostream>
#include <fstream> 
#include <sstream> 
#include <iomanip>
#include <rapidxml.hpp>
#include <rapidxml_utils.hpp>

using namespace OpenSim;
using namespace rapidxml;
using namespace SimTK;

bool parseSettingsFile(
	std::string settings_path,
	Vector_<Vec3> & points,
	std::vector<std::string> & frames);

int main(int argc, const char * argv[])
{
	// Handle command line arguments, checking that we have neither too little 
	// nor too many.
	/* if (argc < 5) 
	{
		std::cout << "Error: too few command line arguments. See comments at"
			<< " top of source file for the correct number and order of input"
			<< " arguments." << std::endl;
		return 1;
	} 
	else if (argc > 5)
	{
		std::cout << "Error: too many command line arguments. See comments at"
			<< " top of source file for the correct number and order of input"
			<< " arguments." << std::endl;
		return 1;
	}  */
	
	/* std::string model_file = argv[1], states_path = argv[2], 
		settings_path = argv[3], results_directory = argv[4]; */
		
	std::string settings_path = argv[1];
	
	// Load information about Jacobians to be computed from settings file.
	
	Vector_<Vec3> all_points; // Simbody Vectors.
	std::vector<std::string> all_frames; // Standard vector for strings. 
	
	bool status = parseSettingsFile(settings_path, all_points, all_frames);
	
	if (!status) 
	{
		std::cout << "Failed parsing settings file." << std::endl;
		return 1;
	}

	std::cout << all_points << std::endl;
	for (int i = 0; i < all_frames.size(); ++i)
	{
		std::cout << all_frames[i] << std::endl;
	}
	
	/* try 
	{
		// Load OpenSim model from file, initialise state and calculate some
		// dynamic properties. 
		Model osimModel(model_file);
		SimTK::State & si = osimModel.initSystem();
		int n_dofs = osimModel.getMatterSubsystem().getNumMobilities(),
			n_bodies = osimModel.getMatterSubsystem().getNumBodies();
			
		// Create time variable.
		double time;
		
		// Load the states file.
		std::ifstream states_file(states_path);
		
		// Open 
		
	} */
	
}

bool parseSettingsFile(
	std::string settings_path,
	Vector_<Vec3> & points,
	std::vector<std::string> & frames)
{
	// Load & parse xml settings file & assign root node. 
	file<> xml(settings_path.c_str()); // Convert from string to const char *
	xml_document<> doc;
	doc.parse<0>(xml.data());
	xml_node<> *node = doc.first_node();
	
	// Count how many points are to be calculated & create a suitably sized
	// vector (of vectors) to store it.
	const int number_of_points = count_children(node->first_node());
	Vector_<Vec3> internal_points(number_of_points);
	
	// Shift the node over to the first Point. 
	node = node->first_node()->first_node();
	
	// Check that we actually have a first node.
	if (node == NULL) 
	{
		std::cout << "Error: failed to get first point. Check that the settings"
			<< " file is correct." << std::endl;
		return 0;
	}
	
	// Iterate over the points, storing the required information. 
	for (int i=0; i < number_of_points; ++i)
	{
		Vec3 point_from_string;
		std::istringstream point_as_string(node->first_node("location")->value());
		
		for (int j = 0; j < 3; ++j) 
		{
			point_as_string >> point_from_string[j];
		}
		
		internal_points[i] = point_from_string;
		
		frames.push_back(node->first_node("frame")->value());
	}
	
	// Finish by saving the points array. 
	points = internal_points;
	
	return 1;
}