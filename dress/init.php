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
    $inv = yeGet($mn, '_inv_');
    for ($i = 0; $i < yeLen($objs); $i++) {
        $o = yeGet($objs, $i);
        $k = yeGetKeyAt($objs, $i);
        if (yeGetStringAt($o, 'where') == $where) {
            if (!$inv || yeGet($inv, $k)) {
                $entry = ywMenuPushEntry($mn, $k, ygGet('dressup.equip'));
                yeCreateString($where, $entry, 'where');
            }
        }
    }
}

function back_menu($mn)
{
    yeSetIntAt(yeGet($mn, '_main_'), 'cur_mn', $GLOBALS['MAIN_MENU']);
}

function to_file($mn)
{
    echo '================================', "\n";
    echo '================================', "\n";
    echo '=========== to file ! ==========', "\n";
    echo '================================', "\n";
    echo '================================', "\n";

    $ch = yeGet($mn, "_ch_");
    yeRemoveChildByStr($ch, "clothes");
    ygEntToFile2($JSON, $ch, ygGetBinaryRootPath() . "/out.json");
}

function change_hair($mn)
{
    echo '================================', "\n";
    echo '================================', "\n";
    echo '========= Change Hair ! ========', "\n";
    echo '================================', "\n";
    echo '================================', "\n";
    echo '    ( ONLY COLOR SUPPORTED )    ', "\n";
    $idx = (ywMenuGetCurrentByEntity($mn) - 1) * -1; // 0 is 1, and 1 is 0
    $ch = yeGet($mn, "_ch_");
    $hair = yeGet($ch, "hair");
    $hair_mn = ywMenuGetCurSliderSlide($mn);
    $dst_color = yeGetStringAt($hair_mn, "text");
    echo $idx, $dst_color, "\n";
    yeSetStringAt($hair, $idx, $dst_color);
}

function add_sld($slider, $color) {
    $c = yeCreateArray($slider);
    yeCreateString($color, $c, "text");
    yeCreateString('dressup.change_hair', $c, 'action');

}

function menu_setup($wid, $mn, $mn_type) {
    $cu = ywMenuGetCurrentEntry($mn);
    $si = yeGet($cu, "slider_idx");
    $mn_pos = yeGetIntAt($wid, 'mn_pos');
    $dress_type = yeGetStringAt($wid, "dress_type");
    if ($si) {
        yeIncrRef($si);
        yePush($si, $mn, '_csi_');
        echo '$si bef refcount: ', yeRefCount($si), "\n";
    }

    ywMenuClear($mn);
    echo '$si bef 1 refcount: ', yeRefCount($si), "\n";
    if ($mn_type == $GLOBALS['MAIN_MENU']) {
        if ($dress_type != "dress")
            ywMenuPushEntry($mn, 'hairs');
        if ($dress_type != "hair") {
            ywMenuPushEntry($mn, 'torso/robe');
            ywMenuPushEntry($mn, 'pants/skirt');
            ywMenuPushEntry($mn, 'shoes');
        }
        if (yeGetStringAt($wid, "type") == "maker")
            ywMenuPushEntry($mn, "save", ygGet('dressup.to_file'));

        if (yeGet($wid, "quit"))
            ywMenuPushEntry($mn, "quit", yeGet($wid, "quit"));
        else
            ywMenuPushEntry($mn, 'quit', ygGet('FinishGame'));
    } else if ($mn_type == $GLOBALS['HAIR_MENU']) {
        $colors = yeCreateArray();
        add_sld($colors, "white-blonde");
        add_sld($colors, "white-blonde2");
        add_sld($colors, "light-blonde");
        add_sld($colors, "white-cyan");
        add_sld($colors, "white");
        add_sld($colors, "gray");
        add_sld($colors, "gray2");
        add_sld($colors, "blonde");
        add_sld($colors, "brunette");
        add_sld($colors, "blonde2");
        add_sld($colors, "black");
        add_sld($colors, "blue");
        add_sld($colors, "blue2");
        add_sld($colors, "pink");
        add_sld($colors, "pink2");
        add_sld($colors, "gold");
        add_sld($colors, "green");
        add_sld($colors, "raven");
        add_sld($colors, "raven2");
        add_sld($colors, "redhead2");

        $s = ywMenuPushSlider($mn, 'color', $colors);
        if ($mn_pos == 0)
            yeReplaceBack($s, $si, 'slider_idx');
        $style = yeCreateArray();
        add_sld($style, "loose");
        add_sld($style, "princess");
        $s = ywMenuPushSlider($mn, 'style', $style);
        if ($mn_pos == 1)
            yeReplaceBack($s, $si, 'slider_idx');
        echo '$si aff refcount: ', yeRefCount($si), "\n";
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
    yeDestroy($si); // dec ref
}

function reset_character($cwid, $mod, $cw) {
    $char = yeGet($cwid, 'character');
    print("reset c in !!!" . yeEntitiesUsed() . " \n");
    $_c_ = yeGet($cwid, '_c_');
    if ($_c_) {
        lpcsHandlerNullify($_c_);
        yeRemoveChildByEntity($cwid, $_c_);
        yeRemoveChildByStr($char, 'clothes');
        print("reset c __c__ !!!" . yeEntitiesUsed() . " \n");
    }
    lpcsHandlerNullify();
    yesCall(yeGet($mod, "dressUp"), $char);
    $ch = ylpcsCreateHandler($char, $cw, $cwid, '_c_');
    ylpcsHandlerSetPosXY($ch, 10, 10);
    ylpcsHandlerSetOrigXY($ch, 0, 2);
    ylpcsHandlerRefresh($ch);
    ywCanvasMultiplySize(yeGet($ch, "canvas"), 5);
    print("reset c out !!!" . yeEntitiesUsed() . " \n");
}

function action($wid, $eves) {
    print("dress action !!!". yeEntitiesUsed() . "\n");
    $menu = ywCntGetEntry($wid, 0);
    yeRemoveChildByStr($menu, '_ch_');
    yePushBack($menu, yeGet($wid, 'character'), "_ch_");
    yePushBack($menu, $wid, "_main_");
    $cur_mn = yeGetIntAt($wid, "cur_mn");
    menu_setup($wid, $menu, $cur_mn);
    $ret = $YEVE_ACTION;
    $dress_type = yeGetStringAt($wid, "dress_type");
    print("dress action --- !!!" . yeEntitiesUsed() . " \n");

    yeIntRoundBound(yeGet($wid, 'mn_pos'), 0, ywMenuNbEntries($menu) - 1);
    if (yevIsKeyDown($eves, $Y_DOWN_KEY)) {
        yeIncrAt($wid, 'mn_pos');
    } else if (yevIsKeyDown($eves, $Y_UP_KEY)) {
        yeAddAt($wid, 'mn_pos', -1);
    } else if (yevIsKeyDown($eves, $Y_ENTER_KEY)) {
        $pos = yeGetIntAt($wid, 'mn_pos');
        if ($dress_type == "dress")
            $pos = $pos + 1;
        if ($dress_type == "hair" && $pos == 1)
            ywMenuCallActionOnByEntity($menu, $eves, yeGetIntAt($wid, 'mn_pos'));
        else {
            if ($cur_mn == $GLOBALS['MAIN_MENU'] &&
                $pos == $GLOBALS['TORSO_MENU_POS']) {
                yeSetIntAt($wid, 'cur_mn', $GLOBALS['TORSO_MENU']);
                return action($wid, NULL);
            } else if ($cur_mn == $GLOBALS['MAIN_MENU'] &&
                       $pos == $GLOBALS['PANTS_MENU_POS']) {
                yeSetIntAt($wid, 'cur_mn', $GLOBALS['PANTS_MENU']);
                return action($wid, NULL);
            } else if ($cur_mn == $GLOBALS['MAIN_MENU'] &&
                       $pos == $GLOBALS['SHOES_MENU_POS']) {
                yeSetIntAt($wid, 'cur_mn', $GLOBALS['SHOES_MENU']);
                return action($wid, NULL);
            } else if ($cur_mn == $GLOBALS['MAIN_MENU'] &&
                       $pos == $GLOBALS['HAIR_MENU_POS']) {
                yeSetIntAt($wid, 'cur_mn', $GLOBALS['HAIR_MENU']);
                return action($wid, NULL);
            } else {
                ywMenuCallActionOnByEntity($menu, $eves, yeGetIntAt($wid, 'mn_pos'));
            }
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
    print("dress action out !!!" . yeEntitiesUsed() . " \n");
    yirl_return($ret);
}

function init_wid($cwid) {
    echo "INIT WID\n";
    $mod = ygGet("dressup");
    $entries = yeCreateArray($cwid, "entries");
    $menu = yeCreateArray($entries);
    $inv = yeGet($cwid, "char_clothes");
    yeCreateString("menu", $menu, "<type>");
    if ($inv)
        yePushBack($menu, $inv, "_inv_");
    $cw = yeCreateArray($entries);
    yeCreateString("canvas", $cw, "<type>");

    $margin = yeCreateArray($cw, "margin");
    yeCreateString('rgba: 220 10 100 55', $margin, 'color');
    yeCreateInt(3, $margin, 'size');

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
    yeCreateString("maker", $start, "type");
    mk_test_char($start);

    ywidAddSubType($wid_type);

    yeCreateFunction("back_menu", $mod, "back_menu");
    yeCreateFunction("change_hair", $mod, "change_hair");
    yeCreateFunction("to_file", $mod, "to_file");

    print("INIT MOD !!!!!!\n!!!!!\n!!\n!\n");
    yirl_return($mod);
}

?>
