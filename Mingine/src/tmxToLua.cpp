#include <fstream>
#include <iostream>
#include <sstream>
#include <map>
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

	enum PropertyType
	{
		PropertyType_Unknown,
		PropertyType_Bool,
		PropertyType_Float,
		PropertyType_Int
	};

	class Property
	{
	public:
		string name;
		PropertyType propertyType{ PropertyType_Unknown };

		union
		{
			bool b;
			float f;
			int i;
		} value;

		Property()
		{
			// nothing
		}

		Property(string name, bool value)
		{
			this->name = name;
			this->value.b = value;
			this->propertyType = PropertyType_Bool;
		}

		Property(string name, float value)
		{
			this->name = name;
			this->value.f = value;
			this->propertyType = PropertyType_Float;
		}

		Property(string name, int value)
		{
			this->name = name;
			this->value.i = value;
			this->propertyType = PropertyType_Int;
		}
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

	bool toBool(const char* boolString)
	{
		if (strcmp(boolString, "true") == 0)
		{
			return true;
		}
		else if (strcmp(boolString, "false") == 0)
		{
			return false;
		}
		else
		{
			log("Error parsing bool value in tmx file.");
			return false;
		}
	}

	float toFloat(const char* floatString)
	{
		stringstream strValue;
		strValue << floatString;

		float value;
		strValue >> value;

		return value;
	}

	int toInt(const char* intString)
	{
		stringstream strValue;
		strValue << intString;

		int value;
		strValue >> value;

		return value;
	}


	int readIntAttribute(XMLElement* element, const char* intName)
	{
		return toInt(element->Attribute(intName));
	}
		
	void writeStringField(const char* outTableName, const char* valueName, const char* value, string& outString)
	{
		outString += string(outTableName) + "." + valueName + " = \"" + value + "\"\n";
	}

	void writeIntField(const char* outTableName, const char* valueName, int value, string& outString)
	{
		outString += string(outTableName) + "." + valueName + " = " + to_string(value) + "\n";
	}

	void writeLuaMapScript(const MapData& mapData, const map<string, vector<vector<Property>>>& objects, string& outScript)
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

		if (mapData.walkabilityGrid != nullptr)
		{
			outScript += string(mapData.outTableName) + ".walkabilityGrid = {";

			for (int i = 0; i < mapData.mapLength(); ++i)
			{
				outScript += (mapData.walkabilityGrid[i] ? "1," : "0,");
			}

			// erase last comma
			outScript.resize(outScript.size() - 1);
			outScript += "}\n"; // end of walkability grid
		}

		for (auto &objectTypes : objects)
		{
			outScript += objectTypes.first + " = {}\n";

			for (auto& item : objectTypes.second)
			{
				//outScript += "{}, ";
			}

			// erase last comma
			//outScript.resize(outScript.size() - 1);
			//outScript += "}\n";
		}
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

		map<string, vector<vector<Property>>> objects;

		while (pObjectGroupElement != nullptr)
		{
			const char * name = pObjectGroupElement->Attribute("name");
			if (name == nullptr)
			{
				return XML_ERROR_PARSING_ATTRIBUTE;
			}

			snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "Parsing object group %s", name);
			log(stringBuilderBuffer);

			if (strcmp(name, "NoWalk") == 0)
			{
				// create walkability grid the first time we encounter a layer with this name.
				if (mapData.walkabilityGrid == nullptr)
				{
					mapData.walkabilityGrid = new bool[mapData.mapLength()];
					memset(mapData.walkabilityGrid, 1, mapData.mapLength());
				}

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
			else
			{
				XMLElement* pListElement = pObjectGroupElement->FirstChildElement("object");

				while (pListElement != nullptr)
				{
					const char* objectName = pListElement->Attribute("name");

					if (objects.find(objectName) == objects.end())
					{
						objects[objectName] = vector<vector<Property>>();
					}

					int x = readIntAttribute(pListElement, "x") / mapData.tileSize;
					int y = readIntAttribute(pListElement, "y") / mapData.tileSize;
					
					XMLElement* pPropertiesElement = pListElement->FirstChildElement("properties");

					if (pPropertiesElement != nullptr)
					{
						vector<Property> properties;
						
						XMLElement* pPropertyElement = pPropertiesElement->FirstChildElement("property");

						while (pPropertyElement != nullptr)
						{
							const char* name = pPropertyElement->Attribute("name");
							const char* type = pPropertyElement->Attribute("type");
							const char* value = pPropertyElement->Attribute("value");

							Property property;
							
							if (strcmp(type, "bool") == 0)
							{
								property = Property(name, toBool(value));
							}
							else if (strcmp(type, "float") == 0)
							{
								property = Property(name, toFloat(value));
							}
							else if (strcmp(type, "int") == 0)
							{
								property = Property(name, toInt(value));
							}
							else
							{
								log("error parsing object properties in tmx file.");
							}

							properties.push_back(property);

							pPropertyElement = pPropertyElement->NextSiblingElement("property");
						}

						objects[objectName].push_back(properties);
					}
					
					pListElement = pListElement->NextSiblingElement("object");
				}
			}

			pObjectGroupElement = pObjectGroupElement->NextSiblingElement("objectgroup");
		}

		// write file
		log("Encoding tmx as lua script...");
		writeLuaMapScript(mapData, objects, outScript);

		return XML_SUCCESS;
	}

	void readTmx(const char* tmxFile, const char* topPathToMatch, const char* outTableName, string& outScript)
	{
		XMLCheckResult(parseTmx(tmxFile, topPathToMatch, outTableName, outScript));
	}

} // end of namespace mingine 