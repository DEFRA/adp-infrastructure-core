# Flux Templates - THIS IS A TEMPORARY SOLUTION WHICH WILL BE REPLACED BY A DOTNET SOLUTION

The Flux Templates solution provides a pipeline which can be used to auto generate the flux files and folders required when onboarding a new service. The pipeline requires a json manifest which details programme name, services, environments etc...  Using this manifest the solution will generate all the required flux files and directories requires for onboarding the project and creates a branch in adp-services-flux.

Please see example manifests below:

#### **FULL EXAMPLE Structure of the manifest file**
```json
{
    "name": "adp", // MANDATORY
    "teams": [ // MANDATORY - AT LEAST ONE TEAM REQUIRED
        {
            "name": "teamname", // MANDATORY
            "servicecode": "ADP", // MANDATORY
            "services": [ // MANDATORY - AT LEAST ONE SERVICE REQUIRED
                {
                    "name": "calculation-service" // MANDATORY
                },
                {
                    "name": "claim-service", // MANDATORY
                    "backend": true // OPTIONAL - ADD IF DBMIGRATION IS REQUIRED
                },
                {
                    "name": "payment-service", // MANDATORY
                    "backend": true // OPTIONAL - ADD IF DBMIGRATION IS REQUIRED
                },
                {
                    "name": "payment-web-service", // MANDATORY
                    "frontend": true // OPTIONAL - ADD IF INGRESS IS REQUIRED E.G. WEB FRONTEND
                },
                {
                    "name": "web-service", // MANDATORY
                    "frontend": true // OPTIONAL - ADD IF INGRESS IS REQUIRED E.G. WEB FRONTEND
                }
            ],
            "environments": [ // MANDATORY - AT LEAST ONE ENVIRONMENT REQUIRED
                {
                    "name": "snd", // REQUIRED
                    "instances": [ // REQUIRED - ATLEAST ONE VALUE REQUIRED CAN BE A COMBINATION OF 1,2 OR 3
                        "1",
                        "2",
                        "3"
                    ]
                },
                {
                    "name": "dev", // REQUIRED
                    "instances": [ // REQUIRED - ONLY 1 IS ALLOWED
                        "1"
                    ]
                },
                {
                    "name": "tst", // REQUIRED
                    "instances": [ // REQUIRED - ATLEAST ONE VALUE REQUIRED CAN BE BOTH 1 AND 2
                        "1",
                        "2"
                    ]
                },
                {
                    "name": "pre", // REQUIRED
                    "instances": [ // REQUIRED - ONLY 1 IS ALLOWED
                        "1"
                    ]
                },
                {
                    "name": "prd", // REQUIRED
                    "instances": [ // REQUIRED - ONLY 1 IS ALLOWED
                        "1"
                    ]
                }
            ]
        }
    ]
}    
```

#### **MINIMUM EXAMPLE Structure of the manifest file**
```json
{
    "name": "progammename", // MANDATORY
    "teams": [ // MANDATORY - AT LEAST ONE TEAM REQUIRED
        {
            "name": "teamname", // MANDATORY
            "servicecode": "SC", // MANDATORY
            "services": [ // MANDATORY - AT LEAST ONE SERVICE REQUIRED
                {
                    "name": "servicename"
                }
            ],
            "environments": [ // MANDATORY - AT LEAST ONE ENVIRONMENT REQUIRED
                {
                    "name": "snd", // MANDATORY - ALLOWED VALUES snd, dev, tst, pre, prd
                    "instances": [
                        "1" // MANDATORY - WHICH ENVIRONMENT INSTANCE TO USE.  CAN BE 1,2 OR IR CAN BE ALL.  PLEASE LOOK AT FULL EXAMPLE MANIFEST
                    ]
                }
            ]
        }
    ]
}
```