#pragma once
#include <string>
#include <map>
#include "asset.h"

namespace mingine {

class AssetDatabase
{
public:
	int add(LoadParameters& loadParameters, std::string& errorMessage);
	void clear();
	void setBasePath(const char* path);

	template <typename T>
	T* get(int id)
	{
		return (T*)assets[id];
	}

private:
	int nextId{ 0 };
	std::string basePath{ "assets/" };
	std::map<int, Asset*> assets{};
	std::map<std::string, int> assetPaths{};
};

} // end of namespace mingine 