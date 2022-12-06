var rcs_oprf_database = {
    #Revision DEC 06 2022
    # This list contains the mandatory RCS frontal values for OPRF (anno 1997), feel free to add non-OPRF to your aircraft, we don't care.
    "default":                  150,    #default value if target's model isn't listed
    "f-14b":                    12,     
    "F-14D":                    12,     
    "f-14b-bs":                 0.0001, #low so it doesn't show up on radar
    "F-15C":                    10,     #low end of sources
    "F-15D":                    11,     #low end of sources
    "f15-bs":                   0.0001,
    "F-16":                     2,
    "JA37-Viggen":              3,      
    "AJ37-Viggen":              3,      #gone
    "AJS37-Viggen":             3,      
    "JA37Di-Viggen":            3,
    "m2000-5":                  1,      
    "m2000-5B":                 1,
    "m2000-5B-backseat":        0.0001,
    "Blackbird-SR71A":          0.25,
    "Blackbird-SR71B":          0.30,
    "Blackbird-SR71A-BigTail":  0.30,
    "MiG-21bis":                3.5,
    "MiG-21MF-75":              3.5,
    "Typhoon":                  0.5,
    "B-1B":                     6,
    "707":                      100,
    "707-TT":                   100,
    "EC-137D":                  110,
    "KC-137R":                  100,
    "KC-137R-RT":               100,
    "C-137R":                   100,
    "RC-137R":                  100,
    "EC-137R":                  110,
    "E-8R":                     100,
    "KC-10A":                   90,
    "KC-10A-GE":                90,
    "KC-30A":                   75,
    "Voyager-KC":               75,
    "c130":                     80,   
    "Jaguar-GR1":               6,
    "Jaguar-GR3":               6,
    "A-10":                     23.5,
    "A-10-model":               23.5,
    "A-10-modelB":              23.5,
# Drones:
    "QF-4E":                    1,
    "MQ-9":                     1,
    "MQ-9-2":                   1,
# Helis:
    "SH-60J":                   20,      
    "UH-60J":                   20,     
    "uh1":                      20,     
    "212-TwinHuey":             19,     
    "412-Griffin":              19,     
    "ch53e":                    30,
    "Mil-Mi-8":                 25,     #guess, Hunter
    "CH47":                     25,     #guess, Hunter
    "mi24":                     25,     #guess, Hunter
    "tigre":                    6,      #guess, Hunter
# OPRF assets:
# Notice that the non-SEA of these have been very reduced to simulate hard to find in ground clutter
    "depot":                    1,
    "ZSU-23-4M":                0.04,
    "SA-6":                     0.10,
    "buk-m2":                   0.08,
    "S-75":                     0.12,
    "s-200":                    0.14,
    "s-300":                    0.16,
    "MIM104D":                  0.15,
    "truck":                    0.02,
    "missile_frigate":          450, 
    "frigate":                  450,
    "tower":                    0.25,   #gone
    "gci":                      0.50,
    "struct":                   1,
    "rig":                      500,
    "point":                    0.7,
    "hunter":                   0.10,    #sea assets, Hunter
# Automats:
    "MiG-29":                   6,
    "SU-27":                    15,
    "daVinci_SU-34":            8,
    "A-50":                     150,
# Hunter ships
    "USS-NORMANDY":             450,    
    "USS-LakeChamplain":        450,    
    "USS-OliverPerry":          450,    
    "USS-SanAntonio":           450,    
};