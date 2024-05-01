{
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = inputs@{ self, nixpkgs, flake-utils, ... }: 
    flake-utils.lib.eachDefaultSystem (system:
    let
        pkgs = nixpkgs.legacyPackages.${system};
        java = pkgs.jdk21_headless;
        idea =  pkgs.jetbrains.idea-community;
        # idea = pkgs.callPackage pkgs.jetbrains.idea-community { jdk = java; };
        devNativeBuildInputs = [
          idea
          java
          pkgs.maven
        ];

        postgres = pkgs.postgresql_16_jit;
        postgresNativeBuildInputs = [
            postgres
        ];

        env = {
            PGDATA = "./pg";
            PGHOST = "localhost";
        };
    in {
        devShells.default = pkgs.mkShell {
            inherit env;
            nativeBuildInputs = devNativeBuildInputs;
        };

        devShells.postgres = pkgs.mkShell {
            inherit env;

            nativeBuildInputs = postgresNativeBuildInputs;
            postgresConf =
                pkgs.writeText "postgresql.conf" ''
                    # Add Custom Settings
                    log_min_messages = warning
                    log_min_error_statement = error
                    log_min_duration_statement = 100  # ms
                    log_connections = on
                    log_disconnections = on
                    log_duration = on
                    #log_line_prefix = '[] '
                    log_timezone = 'UTC'
                    log_statement = 'all'
                    log_directory = 'pg_log'
                    log_filename = 'postgresql-%Y-%m-%d_%H-%M-%S.log'
                    logging_collector = on
                    log_min_error_statement = error
                '';

            # Post Shell Hook
            shellHook = ''
                echo "Using ${postgres.name}."

                # Setup: other env variables
                export PGHOST=$PGDATA

                # Setup: DB
                if [ ! -d $PGDATA ]
                then
                    pg_ctl initdb -o "-U postgres"
                    cat "$postgresConf" >> $PGDATA/postgresql.conf
                fi

                pg_ctl -o "-p 5555 -k ./" start

                # Convenience aliases
                alias fin="pg_ctl stop && exit"
                alias pg="psql -p 5555 -U postgres"
            '';
        };
    });
}
