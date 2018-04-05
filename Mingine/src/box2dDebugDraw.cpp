#include "box2dDebugDraw.h"
#include <stdexcept>
#include <cmath>
#include "platform.h"

namespace mingine {
		
	void box2dDebugDrawCamera::transformVec2(const b2Vec2& v, int& outX, int& outY)
	{
		outX = x + (int)round(v.x * worldToScreenScale);
		outY = y + (int)round(-v.y * worldToScreenScale);
	}

	void box2dDebugDraw::DrawPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)
	{
		SetDrawColor(color);

		// to connect the last vertex to the first in the list.
		b2Vec2 v1 = vertices[vertexCount - 1];
		
		for (int32 i = 0; i < vertexCount; ++i)
		{
			b2Vec2 v2 = vertices[i];
						
			int x1, y1, x2, y2;
			camera.transformVec2(v1, x1, y1);
			camera.transformVec2(v2, x2, y2);
			
			drawLine(x1, y1, x2, y2);

			v1 = v2;
		}
	}

void box2dDebugDraw::DrawSolidPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color)
{
	// for now, ignore the requested for a solid fill...
	DrawPolygon(vertices, vertexCount, color);
}

void box2dDebugDraw::DrawCircle(const b2Vec2& center, float32 radius, const b2Color& color)
{
	throw std::logic_error("Not implemented.");
}

void box2dDebugDraw::DrawSolidCircle(const b2Vec2& center, float32 radius, const b2Vec2& axis, const b2Color& color)
{
	throw std::logic_error("Not implemented.");
}

void box2dDebugDraw::DrawSegment(const b2Vec2& p1, const b2Vec2& p2, const b2Color& color)
{
	throw std::logic_error("Not implemented.");
}

//@TODO: For now, just draw transform as a point.
void box2dDebugDraw::DrawTransform(const b2Transform& xf)
{
	throw std::logic_error("Not implemented.");
}

//@TODO: implement use of size parameter.
void box2dDebugDraw::DrawPoint(const b2Vec2& p, float32 size, const b2Color& color)
{
	SetDrawColor(color);

	int x1, y1;
	camera.transformVec2(p, x1, y1);
	drawPoint(x1, y1);
}

void box2dDebugDraw::SetDrawColor(const b2Color& color)
{
	RenderParameters renderParameters;

	renderParameters.u8[0] = (uint8_t)(color.r * 255);
	renderParameters.u8[1] = (uint8_t)(color.g * 255);
	renderParameters.u8[2] = (uint8_t)(color.b * 255);
	renderParameters.u8[3] = (uint8_t)(color.a * 255);

	setRenderState(Render::DrawColor, renderParameters);
}

} // end of namespace mingine 