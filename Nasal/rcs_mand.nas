var rcs_oprf_database = {
    #Revision MAY 05 2021
    # This list contains the mandatory RCS frontal values for OPRF (anno 1997), feel free to add non-OPRF to your aircraft we don't care.
    "default":                  150,    #default value if target's model isn't listed
    "f-14b":                    12,     
    "F-14D":                    12,     
    "f-14b-bs":                 0.0001,   # low so it dont show up on radar
    "F-15C":                    10,     #low end of sources
    "F-15D":                    11,     #low end of sources
    "f15-bs":                   0.0001,
    "F-16":                     2,
    "JA37-Viggen":              3,      
    "AJ37-Viggen":              3,      # gone
    "AJS37-Viggen":             3,      
    "JA37Di-Viggen":            3,
    "m2000-5":                  1,      
    "m2000-5B":                 1,
    "m2000-5B-backseat":        0.0001,
    "707":                      100,    
    "707-TT":                   100,    
    "EC-137D":                  110,    
    "B-1B":                     6,
    "Blackbird-SR71A":          0.25,
    "Blackbird-SR71B":          0.30,
    "Blackbird-SR71A-BigTail":  0.30,
    "MiG-21bis":                3.5,
    "MiG-21MF-75":              3.5,
    "KC-137R":                  100,    
    "KC-137R-RT":               100,
    "KC-10A":                   100,    
    "Typhoon":                  0.5,
    "C-137R":                   100,    
    "RC-137R":                  100,    
    "EC-137R":                  110,    
    "c130":                     100,   
    "Jaguar-GR1":               6,
    "Jaguar-GR3":               6,
    "A-10":                     23.5,
    "A-10-model":               23.5,
    "A-10-modelB":              23.5,
# Drones:
    "QF-4E":                    1,
    "MQ-9":                     1,
# Helis:
    "SH-60J":                   30,      
    "UH-60J":                   30,     
    "uh1":                      30,     
    "212-TwinHuey":             25,     
    "412-Griffin":              25,     
    "ch53e":                    20,
    "Mil-Mi-8":                 30,     #guess, Hunter
    "CH47":                     20,     #guess, Hunter
    "mi24":                     25,     #guess, Hunter
    "tigre":                    6,      #guess, Hunter
# OPRF assets:
# Notice that the non-SEA of these have been very reduced to simulate hard to find in ground clutter
    "depot":                    0.17,
    "ZSU-23-4M":                0.03,
    "buk-m2":                   0.07,
    "S-75":                     0.09,
    "truck":                    0.15,
    "missile_frigate":          450, 
    "frigate":                  450,   
    "tower":                    0.60,       # gone
    "gci":                      0.50,
    "s-300":                    0.17,
    "MIM104D":                  0.17,
    "struct":                   0.17,   
    "rig":                      500,
    "point":                    0.12,
# Automats:
    "MiG-29":                   6,
    "SU-27":                    15,
# Hunter ships
    "USS-NORMANDY":             450,    
    "USS-LakeChamplain":        450,    
    "USS-OliverPerry":          450,    
    "USS-SanAntonio":           450,    
};