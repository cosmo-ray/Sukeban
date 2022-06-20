<?php

  /*
    --Copyright (C) 2022 Matthias Gatto
    --
    --This program is free software: you can redistribute it and/or modify
    --it under the terms of the GNU Lesser General Public License as published by
    --the Free Software Foundation, either version 3 of the License, or
    --(at your option) any later version.
    --
    --This program is distributed in the hope that it will be useful,
    --but WITHOUT ANY WARRANTY; without even the implied warranty of
    --MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    --GNU General Public License for more details.
    --
    --You should have received a copy of the GNU Lesser General Public License
    --along with this program.  If not, see <http://www.gnu.org/licenses/>.   
  */


$MAIN_MENU = 0;
$HAIR_MENU = 1;
$TORSO_MENU = 2;
$PANTS_MENU = 3;
$SHOES_MENU = 4;

$TORSO_MENU_POS = 1;
$PANTS_MENU_POS = 2;
$SHOES_MENU_POS = 3;

function clothe_mn_setup($mn, $where)
{
    $objs = ygGet('dressup.objects');
    for ($i = 0; $i < yeLen($objs); $i++) {
        $o = yeGet($objs, $i);
        if (yeGetStringAt($o, 'where') == $where) {
            $entry = ywMenuPushEntry($mn, yeGetKeyAt($objs, $i), ygGet('dressup.equip'));
            yeCreateString($where, $entry, 'where');
        }
    }
}

function back_menu($mn)
{
    yeSetIntAt(yeGet($mn, '_main_'), 'cur_mn', $GLOBALS['MAIN_MENU']);
}

function change_hair($mn)
{
    echo '================================', "\n";
    echo '================================', "\n";
    echo '========= Change Hair ! ========', "\n";
    echo '================================', "\n";
    echo '================================', "\n";
}

function menu_setup($wid, $mn, $mn_type) {
    $cu = ywMenuGetCurrentEntry($mn);
    $si = yeGet($cu, "slider_idx");
    if ($si) {
        yePush($si, $mn, '_csi_');
    }

    ywMenuClear($mn);
    if ($mn_type == $GLOBALS['MAIN_MENU']) {
        ywMenuPushEntry($mn, 'hairs');
        ywMenuPushEntry($mn, 'torso/robe');
        ywMenuPushEntry($mn, 'pants/skirt');
        ywMenuPushEntry($mn, 'shoes');
        ywMenuPushEntry($mn, 'quit', ygGet('FinishGame'));
    } else if ($mn_type == $GLOBALS['HAIR_MENU']) {
        $colors = yeCreateArray();
        $c = yeCreateArray($colors);
        // black.png           blonde.png          blonde2.png         blue.png
        yeCreateString('blonde', $c, "text");
        yeCreateString('dressup.change_hair', $c, 'action');

        $c = yeCreateArray($colors);
        yeCreateString('black', $c, "text");
        yeCreateString('dressup.change_hair', $c, 'action');

        $c = yeCreateArray($colors);
        yeCreateString('blue', $c, "text");
        yeCreateString('dressup.change_hair', $c, 'action');

        $s = ywMenuPushSlider($mn, 'test-hair', $colors);
	yeReplaceBack($s, $si, 'slider_idx');
        ywMenuPushEntry($mn, 'back', ygGet('dressup.back_menu'));
    } else if ($mn_type == $GLOBALS['TORSO_MENU']) {
        clothe_mn_setup($mn, 'torso');
        ywMenuPushEntry($mn, 'back', ygGet('dressup.back_menu'));
    } else if ($mn_type == $GLOBALS['PANTS_MENU']) {
        clothe_mn_setup($mn, 'legs');
        ywMenuPushEntry($mn, 'back', ygGet('dressup.back_menu'));
    } else if ($mn_type == $GLOBALS['SHOES_MENU']) {
        clothe_mn_setup($mn, 'feet');
        ywMenuPushEntry($mn, 'back', ygGet('dressup.back_menu'));
    }
    yeRemoveChildByStr($mn, '_csi_');
}

function reset_character($cwid, $mod, $cw) {
    $char = yeGet($cwid, 'character');
    $_c_ = yeGet($cwid, '_c_');
    if ($_c_) {
        lpcsHandlerNullify($_c_);
        yeRemoveChildByEntity($cwid, $_c_);
        yeRemoveChildByStr($char, 'clothes');
    }
    lpcsHandlerNullify();
    yesCall(yeGet($mod, "dressUp"), $char);
    $ch = ylpcsCreateHandler($char, $cw, $cwid, '_c_');
    ylpcsHandlerSetPosXY($ch, 10, 10);
    ylpcsHandlerSetOrigXY($ch, 0, 2);
    ylpcsHandlerRefresh($ch);
    ywCanvasMultiplySize(yeGet($ch, "canvas"), 5);
}

function action($wid, $eves) {
    print("wid action !!!\n");
    $menu = ywCntGetEntry($wid, 0);
    yeRemoveChildByStr($menu, '_ch_');
    yePushBack($menu, yeGet($wid, 'character'), "_ch_");
    yePushBack($menu, $wid, "_main_");
    $cur_mn = yeGetIntAt($wid, "cur_mn");
    menu_setup($wid, $menu, $cur_mn);
    $ret = $YEVE_ACTION;

    yeIntRoundBound(yeGet($wid, 'mn_pos'), 0, ywMenuNbEntries($menu) - 1);
    if (yevIsKeyDown($eves, $Y_DOWN_KEY)) {
        yeIncrAt($wid, 'mn_pos');
    } else if (yevIsKeyDown($eves, $Y_UP_KEY)) {
        yeAddAt($wid, 'mn_pos', -1);
    } else if (yevIsKeyDown($eves, $Y_ENTER_KEY)) {
        $pos = yeGetIntAt($wid, 'mn_pos');
        if ($cur_mn == $GLOBALS['MAIN_MENU'] && $pos == $GLOBALS['TORSO_MENU_POS']) {
            yeSetIntAt($wid, 'cur_mn', $GLOBALS['TORSO_MENU']);
            return action($wid, NULL);
        } else if ($cur_mn == $GLOBALS['MAIN_MENU'] && $pos == $GLOBALS['PANTS_MENU_POS']) {
            yeSetIntAt($wid, 'cur_mn', $GLOBALS['PANTS_MENU']);
            return action($wid, NULL); 
        } else if ($cur_mn == $GLOBALS['MAIN_MENU'] && $pos == $GLOBALS['SHOES_MENU_POS']) {
            yeSetIntAt($wid, 'cur_mn', $GLOBALS['SHOES_MENU']);
            return action($wid, NULL); 
        } else if ($cur_mn == $GLOBALS['MAIN_MENU'] && $pos == $GLOBALS['HAIR_MENU_POS']) {
            yeSetIntAt($wid, 'cur_mn', $GLOBALS['HAIR_MENU']);
            return action($wid, NULL); 
        } else {
            ywMenuCallActionOnByEntity($menu, $eves, yeGetIntAt($wid, 'mn_pos'));
        }
    } else {
        $ret =  $YEVE_NOTHANDLE;
    }

    yeIntRoundBound(yeGet($wid, 'mn_pos'), 0, ywMenuNbEntries($menu) - 1);
    $mn_pos = yeGetIntAt($wid, 'mn_pos');

    ywMenuMove($menu, $mn_pos);

    $mod = ygGet("dressup");
    reset_character($wid, $mod, ywCntGetEntry($wid, 1));
    yeRemoveChildByStr($menu, "_main_");
    yirl_return($ret);
}

function init_wid($cwid) {
    echo "INIT WID\n";
    $mod = ygGet("dressup");
    $entries = yeCreateArray($cwid, "entries");
    $menu = yeCreateArray($entries);
    yeCreateString("menu", $menu, "<type>");
    $cw = yeCreateArray($entries);
    yeCreateString("canvas", $cw, "<type>");

    yeCreateInt(0, $cwid, 'mn_pos');
    yeCreateInt($MAIN_MENU, $cwid, 'cur_mn');
    yeCreateInt(20, $cwid, 'size');
    yeCreateInt(0, $cwid, 'current');
    yeCreateString('vertical', $cwid, 'cnt-type');
    if (yeGetInt(yeGet($cwid, "is_test_wid"))) {
        $objects = ygFileToEnt($JSON, "../items/clothes.json");
        yePushBack($mod, $objects, '_objects_');
        yesCall(yeGet($mod, "setObjects"), 'dressup._objects_');
    }
    yeCreateFunction('action', $cwid, 'action');

    reset_character($cwid, $mod, $cw);
    yirl_return_wid($cwid, "container");
}

function mk_test_char($wid) {
    $ch = yeCreateArray($wid, "character");
    yeCreateString("female", $ch, "sex");
    $hair = yeCreateArray($ch, "hair");
    yeCreateString("princess", $hair);
    yeCreateString("white-blonde2", $hair);
    yeCreateString("light", $ch, "type");
    $eq = yeCreateArray($ch, "equipement");
    yeCreateString("white_sleeveless", $eq, "torso");
    yeCreateString("short skirt", $eq, "legs");
    yeCreateString('black_slippers', $eq, 'feet');
}

function mod_init($mod) {
    echo "Hello world! " . $mod .  PHP_EOL;
    $wid_type = yeCreateArray();
    yeCreateString("dressup", $wid_type, "name");
    yeCreateFunction("init_wid", $wid_type, "callback");
    yeIncrRef($wid_type);

    $start = yeCreateArray($mod, "test_dressup");
    $str = yeCreateString("dressup", $start, "<type>");
    yeCreateInt(1, $start, "is_test_wid");
    yeCreateString("rgba: 255 255 255 255", $start, "background");
    mk_test_char($start);

    ywidAddSubType($wid_type);

    yeCreateFunction("back_menu", $mod, "back_menu");
    yeCreateFunction("change_hair", $mod, "change_hair");

    yirl_return($mod);
}

?>
