#include "assetDatabase.h"
#include <assert.h>
using namespace std;

namespace mingine {

// if the requested asset is already loaded, just return the asset's existing unique id.
// else load it and return a unique id. AssetDatabase treats a font + font size combo as a
// unique asset (so loading the same font file in different sizes results in two different assets,
// but attempting to load one of those previous font + size combos a second time would just return
// the id of the existing asset in the database.
int AssetDatabase::add(LoadParameters& loadParameters, std::string& errorMessage)
{
	errorMessage = string("");

	map<string, int>::iterator it;
	
	// add the base path to the assets here, to keep the scripts relatively uncluttered.
	string fullPath = string(basePath).append(loadParameters.path);
	loadParameters.path = fullPath.c_str();

	if (loadParameters.assetType == AssetFont)
	{
		string mangledFontPath = string(loadParameters.path).append("_" + to_string(loadParameters.size));

		it = assetPaths.find(mangledFontPath);
	}
	else
	{
		it = assetPaths.find(fullPath);
	}
	
    if (it != assetPaths.end())
    {
		return it->second;
    }
	   
    Asset* asset = nullptr;

    switch (loadParameters.assetType)
    {
        case AssetImage:
            asset = new Image();
            break;
        case AssetFont:
            asset = new Font();
            break;
        case AssetSound:
            asset = new Sound();
            break;
        case AssetMusic:
            asset = new Music();
            break;
        default:
            assert(false);
    }

	// generate unique id
	int id = ++nextId;
	assets[id] = asset;

	bool result = asset->load(loadParameters);
	
	if (!result)
	{
		errorMessage.assign(string("Could not load ").append(loadParameters.path));
		return -1;
	}

	assert(result);

	if (loadParameters.assetType == AssetFont)
	{
		string mangledFontPath = string(loadParameters.path).append("_" + to_string(loadParameters.size));
		assetPaths[mangledFontPath] = id;
	}
	else
	{
		assetPaths[loadParameters.path] = id;
	}
	    
    return id;
}

// remove all entries from the asset database
// and free the associated memory.
void AssetDatabase::clear()
{
    for (auto &assetPair : assets)
    {
        assetPair.second->free();
        delete assetPair.second;
    }
        
    assets.clear();
    assetPaths.clear();
}

// use this directory as the root for all paths to assets.
void AssetDatabase::setBasePath(const char* path)
{
	basePath = string(path);
}

} // end of namespace mingine 