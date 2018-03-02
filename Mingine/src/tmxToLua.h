#pragma once
#include <string>

namespace mingine {

// Converts a tmx file to a lua script that can be executed and used to draw the map represented by the tmx file.
// layer rendering is portable. Mingine reserves a specific object layer named "NoWalk" to generate walkability,
// but it is also capable of serializing arbitrary tmx objects to lua objects. This implementation exports scripts
// that create a lua table indexed by object name. for each object name ("enemy", "treasure", etc.), a list of x, y
// positions (in tile space) and any custom properties are provided as table properties, allowing lua to further
// process this markup via a custom script.
void readTmx(const char* tmxFile, const char* topPathToMatch, const char* outTableName, std::string& outScript);

} // end of namespace mingine 