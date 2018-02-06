#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>
#include <assert.h>
using namespace std;

#include "tinyxml2.h"
using namespace tinyxml2;

#include "platform.h"

namespace mingine {

extern char stringBuilderBuffer[MAX_STRING];

class MapData
{
public:
	~MapData() { delete[] walkabilityGrid; }
	int tileSize{};
	int width{};
	int height{};
	const char* tileSetPath{ nullptr };
	const char* outTableName{ nullptr };
	vector<vector<int>> tiles{};
	bool* walkabilityGrid{ nullptr };

	int mapLength() const { return width * height; }
};

void XMLCheckResult(int result)
{
	if (result != XML_SUCCESS)
	{
		snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "XML Error: %i", result);
		log(&stringBuilderBuffer[0]);
		showErrorBox(&stringBuilderBuffer[0]);
	}
}

int readIntAttribute(XMLElement* element, const char* intName)
{
	const char * szAttributeText = element->Attribute(intName);
	stringstream strValue;
	strValue << szAttributeText;

	int value;
	strValue >> value;

	return value;
}

void writeStringField(const char* outTableName, const char* valueName, const char* value, string& outString)
{
	outString += string(outTableName) + "." + valueName + " = \"" + value + "\"\n";
}

void writeIntField(const char* outTableName, const char* valueName, int value, string& outString)
{
	outString += string(outTableName) + "." + valueName + " = " + to_string(value) + "\n";
}

void writeLuaMapScript(const MapData& mapData, string& outScript)
{
	outScript = outScript.append(mapData.outTableName).append(" = {}\n");
	writeStringField(mapData.outTableName, "tileAtlas", mapData.tileSetPath, outScript);
	writeIntField(mapData.outTableName, "tileSize", mapData.tileSize, outScript);
	writeIntField(mapData.outTableName, "width", mapData.width, outScript);
	writeIntField(mapData.outTableName, "height", mapData.height, outScript);

	outScript.append(mapData.outTableName).append(".tiles = {}\n");

	for (size_t layerIndex = 0; layerIndex < mapData.tiles.size(); ++layerIndex)
	{
		outScript += string(mapData.outTableName) + ".tiles[" + to_string(layerIndex + 1) + "] = {";

		for (const int& i : mapData.tiles[layerIndex])
		{
			outScript += to_string(i) + ",";
		}

		// erase last comma
		outScript.resize(outScript.size() - 1);
		outScript += "}\n"; // end of tiles
	}

	outScript += string(mapData.outTableName) + ".walkabilityGrid = {";

	for (int i = 0; i < mapData.mapLength(); ++i)
	{
		outScript += (mapData.walkabilityGrid[i] ? "1," : "0,");
	}

	// erase last comma
	outScript.resize(outScript.size() - 1);
	outScript += "}\n"; // end of tiles
}

int parseTmx(const char* tmxFile, const char* topPathToMatch, const char* outTableName, string& outScript)
{
	XMLDocument xmlDoc;
	XMLError result = xmlDoc.LoadFile(tmxFile);
	XMLCheckResult(result);

	MapData mapData;
	mapData.outTableName = outTableName;

	XMLElement* pMapElement = xmlDoc.RootElement();
	if (pMapElement == nullptr) return XML_ERROR_FILE_READ_ERROR;

	// parse tilesets
	XMLElement* pTilesetElement = pMapElement->FirstChildElement("tileset");
	if (pTilesetElement == nullptr) return XML_ERROR_PARSING_ELEMENT;

	while (pTilesetElement != nullptr)
	{
		const char * name = pTilesetElement->Attribute("name");
		if (name == nullptr) return XML_ERROR_PARSING_ATTRIBUTE;
		
		snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "Parsing tileset %s", name);
		log(stringBuilderBuffer);

		int tileWidth = readIntAttribute(pTilesetElement, "tilewidth");
		int tileHeight = readIntAttribute(pTilesetElement, "tileheight");

		assert(tileWidth == tileHeight);
		mapData.tileSize = tileWidth;
				
		snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "Tile Width: %i Tile Height %i", tileWidth, tileHeight);
		log(stringBuilderBuffer);

		XMLElement* pImageElement = pTilesetElement->FirstChildElement("image");
		const char* source = pImageElement->Attribute("source");
		string s = string(source);
		int index = s.find(topPathToMatch);
		mapData.tileSetPath = &source[index];
		
		snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "Tile atlas source: %s", mapData.tileSetPath);
		log(stringBuilderBuffer);

		pTilesetElement = pTilesetElement->NextSiblingElement("tileset");
	}

	// parse layers
	XMLElement* pLayerElement = pMapElement->FirstChildElement("layer");
	if (pLayerElement == nullptr) return XML_ERROR_PARSING_ELEMENT;

	while (pLayerElement != nullptr)
	{
		const char * name = pLayerElement->Attribute("name");
		if (name == nullptr) return XML_ERROR_PARSING_ATTRIBUTE;
		
		snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "Parsing layer %s", name);
		log(stringBuilderBuffer);

		mapData.width = readIntAttribute(pLayerElement, "width");
		mapData.height = readIntAttribute(pLayerElement, "height");
				
		snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "Map width: %i Map height: %i", mapData.width, mapData.height);
		log(stringBuilderBuffer);

		XMLElement* pDataElement = pLayerElement->FirstChildElement("data");

		stringstream ss(pDataElement->GetText());

		int numLayers = mapData.tiles.size();
		vector<int> v;
		mapData.tiles.push_back(v);

		int i;

		while (ss >> i)
		{
			mapData.tiles[numLayers].push_back(i);

			if (ss.peek() == ',')
			{
				ss.ignore();
			}
		}
				
		pLayerElement = pLayerElement->NextSiblingElement("layer");
	}

	// parse object groups
	XMLElement* pObjectGroupElement = pMapElement->FirstChildElement("objectgroup");
	if (pObjectGroupElement == nullptr) return XML_ERROR_PARSING_ELEMENT;

	mapData.walkabilityGrid = new bool[mapData.mapLength()];
	memset(mapData.walkabilityGrid, 1, mapData.mapLength());

	while (pObjectGroupElement != nullptr)
	{
		const char * name = pObjectGroupElement->Attribute("name");
		if (name == nullptr) return XML_ERROR_PARSING_ATTRIBUTE;
		
		snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "Parsing object group %s", name);
		log(stringBuilderBuffer);

		if (strcmp(name, "NoWalk") == 0)
		{
			XMLElement* pListElement = pObjectGroupElement->FirstChildElement("object");

			while (pListElement != nullptr)
			{
				int x = readIntAttribute(pListElement, "x");
				int y = readIntAttribute(pListElement, "y");
				int w = readIntAttribute(pListElement, "width");
				int h = readIntAttribute(pListElement, "height");

				int row = y / mapData.tileSize;
				int col = x / mapData.tileSize;
				int colliderWidth = w / mapData.tileSize;
				int colliderHeight = h / mapData.tileSize;

				for (int r = row; r < row + colliderHeight; ++r)
				{
					for (int c = col; c < col + colliderWidth; ++c)
					{
						mapData.walkabilityGrid[c + r * mapData.width] = false;
					}
				}

				pListElement = pListElement->NextSiblingElement("object");
			}
		}

		pObjectGroupElement = pObjectGroupElement->NextSiblingElement("objectgroup");
	}

	// write file
	log("Encoding tmx as lua script...");
	writeLuaMapScript(mapData, outScript);

	return XML_SUCCESS;
}

void readTmx(const char* tmxFile, const char* topPathToMatch, const char* outTableName, string& outScript)
{
	XMLCheckResult(parseTmx(tmxFile, topPathToMatch, outTableName, outScript));
}

} // end of namespace mingine 