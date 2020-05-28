#include <yirl/entity.h>
#include <yirl/events.h>
#include <yirl/entity-script.h>
#include <yirl/game.h>
#include <yirl/canvas.h>
#include <yirl/texture.h>

#define YW_PATH_WENT_LEFT 1
#define YW_PATH_WENT_RIGHT 2
#define YW_PATH_WENT_UP 4
#define YW_PATH_WENT_DOWN 8
#define YW_PATH_ALL_BLOCK (YW_PATH_WENT_LEFT | YW_PATH_WENT_RIGHT |	\
			   YW_PATH_WENT_UP | YW_PATH_WENT_DOWN)
#define YW_PATH_LAST YW_PATH_WENT_DOWN

static int pathfindingChooseDirection(Entity *canvas,
				      Entity *curDirInfo, Entity *to,
				      Entity *newDirInfo)
{
	Entity *curRect = yeGet(curDirInfo, 0);
	Entity *tmpRect = ywRectCreateEnt(curRect, NULL, NULL);
	uint32_t curDir = yeGetIntAt(curDirInfo, 1);
	uint32_t optimalArray[4];
	// gcc give the posibility to set sparse array at variable declaration
	// I should use this instead of that ugly s***
	static int32_t optimalArrayOp[YW_PATH_LAST + 1][2] =
		{ {}, {-1, 0},
		  {1, 0}, {},
		  {0, 1}, {}, {}, {},
		  {0, -1} };
	int x = ywPosX(curRect) - ywPosX(to);
	int y = ywPosY(curRect) - ywPosY(to);
	int ret = 0;

	ywRectPrint(curRect);
	if (x < 0)  {// optimal might be right
		optimalArray[0] = YW_PATH_WENT_RIGHT;
		optimalArray[3] = YW_PATH_WENT_LEFT;
	} else { // optimal might be left
		optimalArray[0] = YW_PATH_WENT_LEFT;
		optimalArray[3] = YW_PATH_WENT_RIGHT;
	}

	if (y < 0) {
		optimalArray[1] = YW_PATH_WENT_UP;
		optimalArray[2] = YW_PATH_WENT_DOWN;
	} else {
		optimalArray[1] = YW_PATH_WENT_DOWN;
		optimalArray[2] = YW_PATH_WENT_UP;
	}

	if (abs(y) > abs(x)) {
		YUI_SWAP_VALUE(optimalArray[0], optimalArray[1]);
		YUI_SWAP_VALUE(optimalArray[2], optimalArray[3]);
	}

	for (int i = 0; i < 4; ++i) {
		yeAutoFree Entity *colArray = NULL;
		int optx = optimalArrayOp[optimalArray[i]][0];
		int opty = optimalArrayOp[optimalArray[i]][1];

		if (curDir & optimalArray[i])
			continue;
		curDir |= optimalArray[i];
		ywPosAddXY(tmpRect, ywRectW(tmpRect) * optx,
			   ywRectH(tmpRect) * opty);
		colArray = ywCanvasNewCollisionsArrayWithRectangle(canvas,
								   tmpRect);
		YE_ARRAY_FOREACH(colArray, col) {
			if (!yeGet(col, "is_npc") &&
			    yeGetIntAt(col, "Collision")) {
				ywPosSubXY(tmpRect, ywRectW(tmpRect) * optx,
					   ywRectH(tmpRect) * opty);
				continue;
			}
		}
		/* ywPosAddXY(tmpRect, -10, 10); */
		yePushBack(newDirInfo, tmpRect, NULL);
		ret = 1;
		break;
	}
	yeSetInt(yeGet(curDirInfo, 1), curDir);
	yeDestroy(tmpRect);
	return ret;
}

static int ywCanvasDoPathfinding_(Entity *canvas, Entity *opos, Entity *to_pos,
				  Entity *speed, Entity *path_array)
{
	if (!path_array)
		return -1;

	int ret = 0;
	int i = 0;
	int max = 100;
	// Entity *tmpPos = ywPosCreateEnt(opos, 0, NULL, NULL);
	Entity *tmpArray = yeCreateArray(NULL, NULL);
	Entity *curDirInfo = yeCreateArray(NULL, NULL);
	Entity *newDirInfo = yeCreateArray(NULL, NULL);

	ywRectCreatePosSize(opos, speed, curDirInfo, NULL);
	ywPosPrint(opos);
	ywPosPrint(yeGet(curDirInfo, 0));
	yeCreateInt(0, curDirInfo, NULL);

	while (i < 10 && ywPosDistance(yeGet(curDirInfo, 0), to_pos) > 50) {
		if (i > max) {
			ret = -1;
			goto out;
		}
		if (!pathfindingChooseDirection(canvas, curDirInfo,
						to_pos, newDirInfo))
			break;
		yePushBack(tmpArray, yeGet(curDirInfo, 0), NULL);
		if (ywRectContainPos(yeGet(newDirInfo, 0), to_pos, 1)) {
			yePushBack(tmpArray, yeGet(newDirInfo, 0), NULL);
			break;
		}
		yeDestroy(curDirInfo);
		curDirInfo = newDirInfo;
		newDirInfo = yeCreateArray(NULL, NULL);
		++i;
	}
	i = 1;
	YE_ARRAY_FOREACH(tmpArray, tmpPos) {
		Entity *goal = yeGet(tmpArray, i);
		if (!goal)
			goal = to_pos;
		while (ywPosMoveToward2(tmpPos, goal,
					ywPosX(speed), ywPosY(speed))) {
			ywPosCreateEnt(tmpPos, 0, path_array, NULL);
		}
		++i;
	}
out:
	yeMultDestroy(curDirInfo, newDirInfo, tmpArray);
	return 0;
}

/**
 * fufill @path_array, with a list of pos, that can be use as movement
 * to move @obj to @to_pos
 * speed is the maximum movement that can be made per iteration
 */
void *ywCanvasDoPathfinding(int n, void **args)
{
	return ywCanvasDoPathfinding_(args[0], args[1], args[2],
				      args[3], args[4]);
}

void *mod_init(int nbArg, void **args)
{
	Entity *mod = args[0];

	YEntityBlock {
		mod.name = "pathfinder";
	}
	ygRegistreFunc(5, "ywCanvasDoPathfinding", "ywCanvasDoPathfinding");
	return mod;
}
