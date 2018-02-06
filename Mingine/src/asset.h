#pragma once

typedef unsigned __int8 Uint8;

namespace mingine {

enum AssetType
{
	AssetImage,
	AssetFont,
	AssetSound,
	AssetMusic,
	AssetUnknown
};

class LoadParameters
{
public:
	const char* path{ nullptr };
	int size{ 0 }; // currently used only for fonts, but could conceivably be useful for other types of assets.
	AssetType assetType{ AssetUnknown };
};

class Asset
{
public:
	Asset();
	virtual ~Asset();

	Asset(const Asset&) = delete;
	Asset& operator= (const Asset&) = delete;

	virtual bool load(const LoadParameters& loadParameters) = 0;
	virtual void free() = 0;

protected:
	void* assetData{ nullptr };
};

class Image : public Asset
{
public:
	bool load(const LoadParameters& loadParameters) override;
	void free() override;
	void draw(int x, int y, double angle, double scale, Uint8 r, Uint8 g, Uint8 b);
	void drawFrame(int x, int y, int frameWidth, int frameHeight, int frame, double angle, double scale, Uint8 r, Uint8 g, Uint8 b);

private:
	int width{ 0 };
	int height{ 0 };
};

class Font : public Asset
{
public:
	bool load(const LoadParameters& loadParameters) override;
	void free() override;
	void draw(const char* text, int x, int y, Uint8 r, Uint8 g, Uint8 b);
};

class Sound : public Asset
{
public:
	bool load(const LoadParameters& loadParameters) override;
	void free() override;
	void play();
};

class Music : public Asset
{
public:
	bool load(const LoadParameters& loadParameters) override;
	void free() override;
	void play();
};

} // end of namespace mingine 