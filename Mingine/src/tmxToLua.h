#pragma once
#include <string>

namespace mingine {

// converts a tmx file to a lua script that can be executed and used to draw the map represented by the tmx file.
// layer rendering is portable. object layer loading is not particularly portable, as this implementation uses 
// object layers just for determining walkability.
void readTmx(const char* tmxFile, const char* topPathToMatch, const char* outTableName, std::string& outScript);

} // end of namespace mingine 