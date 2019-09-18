#include <yirl/entity.h>
#include <yirl/events.h>
#include <yirl/entity-script.h>
#include <yirl/game.h>
#include <yirl/canvas.h>
#include <yirl/texture.h>

void *createHandler(int nbArg, void **args)
{
	Entity *thing = args[0];
	Entity *canvas_wid = args[1];
	Entity *father = args[2];
	const char *name = args[3];
	Entity *s_info = yeGet(thing, "sprite");
	Entity *ret;
	Entity *text;

	if (!s_info) {
		return NULL;
	}
	ret = yeCreateArray(father, name);

	yePushBack(ret, thing, "char");
	yePushBack(ret, s_info, "sp");
	text = ywTextureNewImg(yeGetStringAt(s_info, "path"), NULL,
			       ret, "text");
	yePushBack(ret, canvas_wid, "wid");
	yeCreateInt(0, ret, "x");
	yeCreateInt(0, ret, "y");
	return ret;
}

void *handlerRefresh(int nargs, void **args)
{
	Entity *h = args[0];
	int x = 0, y = 0;
	Entity *w = yeGet(h, "wid");
	Entity *c;
	Entity *ret;
	Entity *sp = yeGet(h, "sp");
	int size = yeGetIntAt(sp, "size");
	int sy = yeGetIntAt(sp, "src-pos");
	yeAutoFree Entity *rect = ywRectCreateInts(0, sy, size, size, NULL, NULL);
	assert(size);

	printf("sy: %d\n", sy);
	if ((c = yeGet(h, "canvas"))) {
		Entity *tmpp = ywCanvasObjPos(c);
		printf("%d %d\n", x, y);
		x = ywPosX(tmpp);
		y = ywPosY(tmpp);
		ywCanvasRemoveObj(w, c);
	}
	ret = ywCanvasNewImgFromTexture(w, x, y, yeGet(h, "text"), rect);
	yePushBack(h, ret, "canvas");
	yeDestroy(ret);
	return h;
}

void *handlerMove(int nbArg, void **args)
{
	Entity *h = args[0];
	Entity *p = args[1];

	if (!yeGet(h, "canvas")) {
		handlerRefresh(0, (void *[]){h});
	}

	ywCanvasObjSetPosByEntity(yeGet(h, "canvas"), p);
}

void *mod_init(int nbArg, void **args)
{
	Entity *mod = args[0];

	YEntityBlock {
		mod.name = "sprite-man";
		mod.createHandler = createHandler;
		mod.handlerRefresh = handlerRefresh;
		mod.handlerMove = handlerMove;
	}
	printf("SPRITE MANAGER !!!\n");
	return mod;
}
