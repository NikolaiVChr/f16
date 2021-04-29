var rcs_oprf_database = {
    # This list contains the mandatory RCS frontal values for OPRF (anno 1997), feel free to add non-OPRF to your aircraft we don't care.
    #REVISION: 2021/04/29
    "default":                  150,    #default value if target's model isn't listed
    "f-14b":                    12,     
    "F-14D":                    12,     
    "f-14b-bs":                 0.0001,   # low so it dont show up on radar
    "F-15C":                    10,     #low end of sources
    "F-15D":                    11,     #low end of sources
    "f15-bs":                   0.0001,
    "F-16":                     2,
    "JA37-Viggen":              3,      #close to actual
    "AJ37-Viggen":              3,      #close to actual
    "AJS37-Viggen":             3,      #close to actual
    "JA37Di-Viggen":            3,      #close to actual
    "m2000-5":                  1,      
    "m2000-5B":                 1,
    "m2000-5B-backseat":        0.0001, 
    "B-1B":                     1,      #previous was 10
    "Blackbird-SR71A":          0.25,
    "Blackbird-SR71B":          0.30,
    "Blackbird-SR71A-BigTail":  0.30,
    "MiG-21bis":                3.5,
    "MiG-21MF-75":              3.5,
    "KC-137R":                  90,     #guess
    "KC-137R-RT":               90,     #guess
    "C-137R":                   85,     #guess
    "RC-137R":                  95,     #guess
    "EC-137R":                  100,    #guess
    "E-8R":                     95,     #guess
    "KC-10A":                   90,     #guess
    "KC-10A-GE":                90,     #guess
    "KC-30A":                   75,     #guess
    "Voyager-KC":               75,     #guess
    "707":                      85,     #guess
    "707-TT":                   90,     #guess
    "EC-137D":                  100,    #guess
    "c130":                     80,   
    "Jaguar-GR1":               6,
    "A-10":                     23.5,
    "A-10-model":               23.5,
    "A-10-modelB":              23.5,
    "Typhoon":                  0.5,
# Drones:
    "QF-4E":                    2,      #actual: 6
    "MQ-9":                     0.75,   #guess
    "MQ-9-2":                   0.75,   #guess
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
    "depot":                    170,
    "ZSU-23-4M":                3,
    "S-75":                     13,
    "buk-m2":                   7,   
    "truck":                    1.5,
    "missile_frigate":          450, 
    "frigate":                  450,   
    "tower":                    60,       
    "gci":                      50,
    "s-300":                    17,
    "MIM104D":                  17,
    "struct":                   170,   
    "rig":                      500,
    "point":                    120,
# Automats:
    "MiG-29":                   6,
    "SU-27":                    15,
# Hunter ships
    "USS-NORMANDY":             450,    
    "USS-LakeChamplain":        450,    
    "USS-OliverPerry":          450,    
    "USS-SanAntonio":           450,    
};