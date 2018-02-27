#pragma once

typedef unsigned char uint8_t;

namespace mingine {

const int MAX_STRING = 512;

namespace Render
{
	enum Setting
	{
		DrawColor,
		LogicalSize,
		Scale,
	};
}

// unifies passing of parameters to set various render states,
// which frees us from writing a new function per render state setting.
union RenderParameters
{
	int i[4];
	uint8_t u8[4];
	float f[2];
};

void log(const char* message);
void showErrorBox(const char* message);
bool initPlatform(int screenWidth, int screenHeight, bool fullscreen);
void freePlatform();
void setWindowTitle(const char* title);
bool pollEvents(void(*eventHandler)(const char*, int value));
void updateInput(int* mouseX, int* mouseY);
bool isMouseButtonDown(int buttonId);
void getRenderState(Render::Setting renderSetting, RenderParameters& renderParameters);
void setRenderState(Render::Setting renderSetting, RenderParameters& renderParameters);
void drawPoint(int x, int y);
void drawLine(int startX, int startY, int endX, int endY);
void drawCircle(int x, int y, int radius);
void drawRect(int x, int y, int w, int h);
void fillRect(int x, int y, int w, int h);
void clearScreen(uint8_t r, uint8_t g, uint8_t b);
void beginFrame();
void presentFrame();
void presentFrameRotating();
void stopMusic();
void endUpdate();

} // end of namespace mingine 
