module hunt.framework.config.AuthUserConfig;

import hunt.framework.Init;

import std.algorithm;
import std.array;
import std.conv;
import std.file;
import std.path;
import std.stdio;
import std.range;
import std.string;

import hunt.logging;


/**
 * Convert the permission format from Hunt to Shiro, which means that 
 * all the '.' will be replaced with the ':'.
 */
static string toShiroPermissions(string value) {
    return value.replace('.', ':');
}

/**
 * 
 */
class AuthUserConfig {
    static class User {
        string name;
        string password;
        string[] roles;

        override string toString() {
            return "name: " ~ name ~ ", role: " ~ roles.to!string();
        }
    }

    static class Role {
        string name;

        /**
         * Examples:
         *  printer:query,print:lp7200
         * 
         * See_also:
         *  https://shiro.apache.org/permissions.html
         */
        string[] permissions;

        override string toString() {
            return "name: " ~ name ~ ", permissions: " ~ permissions.to!string();
        }
    }

    User[] users;

    Role[] roles;

    static AuthUserConfig load(string userConfigFile, string roleConfigFile) {
        version(HUNT_DEBUG) {
            tracef("Loading users from %s", userConfigFile);
            tracef("Loading roles from %s", roleConfigFile);
        }
        
        AuthUserConfig config = new AuthUserConfig();

        if (exists(userConfigFile)) {
            File f = File(userConfigFile, "r");
            scope(exit) f.close();

            string line;
            while((line = f.readln()) !is null) {
                line = line.strip();

                if(line.empty) continue;

                if (line[0] == '#' || line[0] == ';')
                    continue;

                string[] parts = split(line, " ");
                if(parts.length < 2) continue;

                string fieldValue;
                string password;
                string roles;

                int fieldIndex = 1;
                foreach(string v; parts[1..$]) {
                    fieldValue = v.strip();
                    if(fieldValue.empty) continue;

                    if(fieldIndex == 1) password = fieldValue;
                    if(fieldIndex == 2) roles = fieldValue;

                    fieldIndex++;
                    if(fieldIndex > 2) break;
                }

                User user = new User();
                user.name = parts[0].strip();
                user.password = password;
                user.roles = roles.split("|");

                config.users ~= user;
            }
        }

        
        if (exists(roleConfigFile)) {
            File f = File(roleConfigFile, "r");
            scope(exit) f.close();

            string line;
            while((line = f.readln()) !is null) {
                line = line.strip();

                if(line.empty) continue;

                if (line[0] == '#' || line[0] == ';')
                    continue;

                string[] parts = split(line, " ");
                if(parts.length < 2) continue;

                Role role = new Role();
                role.name = parts[0].strip();

                string permissions;
                foreach(string v; parts[1..$]) {
                    permissions = v.strip();
                    if(!permissions.empty) break;
                }

                role.permissions = permissions.split("|").map!(p => p.strip().toShiroPermissions()).array;
                config.roles ~= role;
            }            
        }

        return config;

    }
}