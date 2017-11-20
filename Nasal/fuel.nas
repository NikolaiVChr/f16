# FUEL ==============================================================
# Initialize correct amount of fuel based on loadout configuration
#
# Known issue is that this doesn't run when a different livery is selected @runtime
# which can load a different external loadout configuration!

var initExtTankFuel = func {
        var checkWingtanks = props.globals.getNode("sim/model/f16/wingtanks");
        var initFuelRightWingtank = props.globals.getNode("consumables/fuel/tank[2]/level-gal_us");
        var initFuelLeftWingtank = props.globals.getNode("consumables/fuel/tank[3]/level-gal_us");

        var checkVentraltank = props.globals.getNode("sim/model/f16/ventraltank");
        var initFuelVentraltank = props.globals.getNode("consumables/fuel/tank[4]/level-gal_us");


        if (checkWingtanks.getBoolValue()) {
                initFuelRightWingtank.setValue(370);
                initFuelLeftWingtank.setValue(370);
#               print("EPIC, initRightWingTankFuel true: ", initFuelRightWingtank.getValue());
#               print("EPIC, initLeftWingTankFuel true: ", initFuelLeftWingtank.getValue());
        } else {
                initFuelRightWingtank.setValue(0);
                initFuelLeftWingtank.setValue(0);
#               print("EPIC, initRightWingTankFuel false: ", initFuelRightWingtank.getValue());
#               print("EPIC, initLeftWingTankFuel false: ", initFuelLeftWingtank.getValue());
        }

        if (checkVentraltank.getBoolValue()) {
                initFuelVentraltank.setValue(300);
#               print("EPIC, initVentralTankFuel true: ", initFuelVentraltank.getValue());
        } else {
                initFuelVentraltank.setValue(0);
#               print("EPIC, initVentralTankFuel false: ", initFuelVentraltank.getValue());
        }
}

#initExtTankFuel();
