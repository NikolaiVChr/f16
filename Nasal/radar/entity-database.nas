# A database of flying, surface and marine entities. Inspired from MiG-21bis.

var Database = {
	"default": {
		isHeli: 0,
		isAircraft: 1,
		isShip: 0,
		isSurfaceAsset: 0,
		isAwacs: 0,
		isCarrier: 0,

		rcsFrontal: 400,
		
		hasRadar: 0,
		passiveRadarRange: 70,# Distance in nm that antiradiation weapons can home in on the the radiation.		
		radarFieldRadius: 60,
		radarEmitterCode: "S",
		rwrCode: "U",
		baseThreat: func (my_deviation_from_him_deg) {return 0;},
		baseDangerNM: 50,
		},
	"f16": {},
};