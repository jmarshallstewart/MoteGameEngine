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

	// A region of memory set aside as a scratchad for building debug strings.
	extern char stringBuilderBuffer[MAX_STRING];

	// MapData is just a container to store data
	// about a map loaded from a tmx file.
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

	// Properties can store different types of values, see below.
	enum PropertyType
	{
		PropertyType_Unknown,
		PropertyType_Bool,
		PropertyType_Float,
		PropertyType_Int,
		PropertyType_String
	};

	// A Property represents a key-value pair consisting of a name and a value. The value
	// can be a bool, float, or int. This class is used as an intermediate format
	// when converting from tmx objects to lua script.
	class Property
	{
	public:
		// each property has a name such as "maxSpeedX" or "startingHitPoints"
		string name;

		// without knowing what type of value the property represents,
		// we will not be able to interpret the value union (see below)
		// correctly.
		PropertyType propertyType{ PropertyType_Unknown };

		// properties can store different types of values, but we
		// use the same memory for that value (which will be the size of
		// the largest type in the union).
		union
		{
			bool b;
			float f;
			int i;
			const char* s;
		} value{};

		// these constructors exploit function overload lookup
		// to make it easy to create properties from arbitrary
		// values of various types.

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

		Property(string name, const char* value)
		{
			this->name = name;
			this->value.s = value;
			this->propertyType = PropertyType_String;
		}

		// returns the printable version of the value
		// of this property.
		string getValueString() const
		{
			switch (propertyType)
			{
			case PropertyType_Unknown:
				return "\"unknown\"";
			case PropertyType_Bool:
				return value.b ? "true" : "false";
			case PropertyType_Float:
				return to_string(value.f);
			case PropertyType_Int:
				return to_string(value.i);
			case PropertyType_String:
			{
				string s = string("\"") + string(value.s) + string("\"");
				return s;
			}
			default:
				log("Unknown property type sent to getValueString()");
				return to_string(value.i);
			}
		}
	};

	// checks the results of various operations using tinyXml and 
	// displays an error box is there was an issue reading an xml file.
	void XMLCheckResult(int result)
	{
		if (result != XML_SUCCESS)
		{
			snprintf(stringBuilderBuffer, sizeof(stringBuilderBuffer), "XML Error: %i", result);
			log(&stringBuilderBuffer[0]);
			showErrorBox(&stringBuilderBuffer[0]);
		}
	}

	// converts a string to a bool
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

	// converts a string to a float
	float toFloat(const char* floatString)
	{
		stringstream strValue;
		strValue << floatString;

		float value;
		strValue >> value;

		return value;
	}

	// converts a string to an int
	int toInt(const char* intString)
	{
		stringstream strValue;
		strValue << intString;

		int value;
		strValue >> value;

		return value;
	}
	
	// reads an xml attribute from an xml element and converts it to an int.
	int readIntAttribute(XMLElement* element, const char* intName)
	{
		return toInt(element->Attribute(intName));
	}
	
	// helper function for generating a lua script to add a string value to a table.
	void writeStringField(const char* outTableName, const char* valueName, const char* value, string& outString)
	{
		outString += string(outTableName) + "." + valueName + " = \"" + value + "\"\n";
	}

	// helper function for generating a lua script to add an int value to a table.
	void writeIntField(const char* outTableName, const char* valueName, int value, string& outString)
	{
		outString += string(outTableName) + "." + valueName + " = " + to_string(value) + "\n";
	}

	// Tiled uses a properties block for custom properties, which both the map
	// and the objects in the object layers both have. This function populates
	// the vector properties with the properties in the tmx file. All bool, float,
	// int, and string properties are supported (all available tmx properties at
	// the time this was written).
	void ReadProperties(XMLElement* pElement, vector<Property>& properties)
	{
		XMLElement* pPropertiesElement = pElement->FirstChildElement("properties");

		if (pPropertiesElement != nullptr)
		{
			XMLElement* pPropertyElement = pPropertiesElement->FirstChildElement("property");

			while (pPropertyElement != nullptr)
			{
				const char* name = pPropertyElement->Attribute("name");
				const char* type = pPropertyElement->Attribute("type");
				const char* value = pPropertyElement->Attribute("value");

				Property property;

				if (type == nullptr)
				{
					property = Property(name, value);
				}
				else if (strcmp(type, "bool") == 0)
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
		}
	}

	void writeLuaMapScript(const MapData& mapData, const vector<Property>& mapProperties, const map<string, vector<vector<Property>>>& objects, string& outScript)
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

		string objectListScript = "";

		for (auto &objectTypes : objects)
		{
			objectListScript += string(mapData.outTableName) + "." + objectTypes.first + " = {";

			for (auto& item : objectTypes.second)
			{
				objectListScript += "{";

				for (auto& p : item)
				{
					objectListScript += p.name + " = " + p.getValueString() + ", ";
				}

				objectListScript += "}, ";
			}
	
			objectListScript += "}\n";
		}

		outScript += objectListScript;

		for (size_t i = 0; i < mapProperties.size(); ++i)
		{
			const Property& p = mapProperties[i];
			outScript += string(mapData.outTableName) + "." + p.name + " = " + p.getValueString() + "\n";
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

		vector<Property> mapProperties;
		ReadProperties(pMapElement, mapProperties);

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

					vector<Property> properties;

					// store object coordinates
					properties.push_back(Property("x", readIntAttribute(pListElement, "x") / mapData.tileSize));
					properties.push_back(Property("y", readIntAttribute(pListElement, "y") / mapData.tileSize));
										
					ReadProperties(pListElement, properties);

					objects[objectName].push_back(properties);
					
					pListElement = pListElement->NextSiblingElement("object");
				}
			}

			pObjectGroupElement = pObjectGroupElement->NextSiblingElement("objectgroup");
		}

		// write file
		log("Encoding tmx as lua script...");
		writeLuaMapScript(mapData, mapProperties, objects, outScript);
		
		return XML_SUCCESS;
	}

	void readTmx(const char* tmxFile, const char* topPathToMatch, const char* outTableName, string& outScript)
	{
		XMLCheckResult(parseTmx(tmxFile, topPathToMatch, outTableName, outScript));
	}

} // end of namespace mingine 