#pragma once
#ifdef _WIN32
#include <Box2D.h>
#else
#include <Box2D/Box2D.h>
#endif


namespace mingine {

	class box2dDebugDrawCamera
	{
	public:
		int x{ 0 };
		int y{ 0 };
		float worldToScreenScale{ 8.0f };

		void transformVec2(const b2Vec2& v, int& outX, int& outY);
	};

	class box2dDebugDraw : public b2Draw
	{
	public:
		// @TODO: add function to set a camera.
		box2dDebugDrawCamera camera;

		// implement the functions required by Box2D's b2Draw interface.
		void DrawPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color) override;
		void DrawSolidPolygon(const b2Vec2* vertices, int32 vertexCount, const b2Color& color) override;
		void DrawCircle(const b2Vec2& center, float32 radius, const b2Color& color) override;
		void DrawSolidCircle(const b2Vec2& center, float32 radius, const b2Vec2& axis, const b2Color& color) override;
		void DrawSegment(const b2Vec2& p1, const b2Vec2& p2, const b2Color& color) override;
		void DrawTransform(const b2Transform& xf) override;
		void DrawPoint(const b2Vec2& p, float32 size, const b2Color& color) override;

	private:
		void SetDrawColor(const b2Color& color);
	};

} // end of namespace mingine 