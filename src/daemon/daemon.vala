/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * daemon.vala
 * Copyright (C) Nicolas Bruguier 2012 <gandalfn@club-internet.fr>
 *
 * glucose-board is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * glucose-board is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace GlucoseBoard
{
    // static methods
    internal class DaemonLogger : GlucoseBoard.Log.Logger
    {
        private unowned Daemon m_Daemon = null;

        public DaemonLogger (Daemon inDaemon)
        {
            GLib.Object (domain: "glucose-board-daemon", level: Log.Level.DEBUG, formatted: false);

            m_Daemon = inDaemon;
        }

        public override void
        write (string inDomain, GlucoseBoard.Log.Level inLevel, string inMessage)
        {
            m_Daemon.message (inLevel, inMessage);
        }
    }

    /**
     * Module manager daemon, this object and its methods are only accessible by DBUS
     * on interface ``org.freedesktop.GlucoseBoard.Daemon``
     */
    [DBus (name = "org.freedesktop.GlucoseBoard.Daemon")]
    public class Daemon : GLib.Object
    {
        // properties
        private GLib.DBusConnection         m_Connection;
        private ExtensionLoader<DBusModule> m_Loader;
        private GLib.List<DBusModule>       m_Plugins;

        // signals
        public signal void message (GlucoseBoard.Log.Level inLevel, string inMessage);

        // methods
        internal Daemon(GLib.DBusConnection inConnection)
        {
            Log.debug_mc ("daemon", "main", "Create daemon");

            // Get dbus connection
            m_Connection = inConnection;

            // Create plugin list
            m_Plugins = new GLib.List<DBusModule> ();

            // Create extension loader
            m_Loader = new ExtensionLoader<DBusModule> ();

            // Load all plugins
            foreach (unowned Extension<DBusModule> extension in m_Loader)
            {
                try
                {
                    extension.load ();
                    DBusModule plugin = extension.create (inConnection);
                    m_Plugins.prepend (plugin);
                }
                catch (ExtensionError err)
                {
                    Log.error_mc ("daemon", "main", "Error on loading daemons: %s", err.message);
                }
            }
        }

        /**
         * Return the list of module list managed by daemon daemon
         *
         * @return string array of module name managed by daemon daemon
         */
        public string[]
        get_module_list ()
        {
            Log.debug_mc ("daemon", "main", GLib.Log.METHOD);

            string[] names = {};

            foreach (unowned Extension<DBusModule> extension in m_Loader)
            {
                names += extension.name;
            }

            return names;
        }

        /**
         * Return the description of inName module
         *
         * @param inName the name of the module
         *
         * @return the description of inName module
         */
        public string
        get_module_description (string inName)
        {
            Log.debug_mc ("daemon", "main", GLib.Log.METHOD);

            foreach (unowned Extension<DBusModule> extension in m_Loader)
            {
                if (inName == extension.name)
                    return extension.description;
            }

            return "";
        }

        /**
         * Return the dbus object name of inName module
         *
         * @param inName the name of the module
         *
         * @return the dbus object name of inName module
         */
        public string
        get_module_dbus_object (string inName)
        {
            Log.debug_mc ("daemon", "main", GLib.Log.METHOD);

            foreach (unowned Extension<DBusModule> extension in m_Loader)
            {
                if (inName == extension.name)
                    return extension.dbus_name;
            }

            return "";
        }
    }

    static bool sNoDaemon = false;

    const GLib.OptionEntry[] cOptionEntries =
    {
        { "no-daemonize", 'd', 0, GLib.OptionArg.NONE, ref sNoDaemon, "Do not run glucose-board-daemon as a daemonn", null },
        { null }
    };

    static int
    main (string[] inArgs)
    {
        //Log.set_default_logger (new Log.Syslog (Log.Level.DEBUG, "glucose-board-daemon"));
        Log.set_default_logger (new Log.Stderr (Log.Level.DEBUG, "glucose-board-daemon"));
        try
        {
            GLib.OptionContext opt_context = new OptionContext("- GlucoseBoard Devices daemon");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(cOptionEntries, "glucose-board-daemon");
            opt_context.parse(ref inArgs);
        }
        catch (GLib.OptionError err)
        {
            Log.critical_mc ("daemon", "main", "option parsing failed: %s", err.message);
            return 1;
        }

        if (!sNoDaemon)
        {
            if (Posix.daemon (0, 0) < 0)
            {
                Log.critical_mc ("daemon", "main", "error on launch has daemon");
                return 1;
            }
        }

        Log.debug_mc ("daemon", "main", "start");

        //GlucoseBoard.ExtensionLoader.add_search_path (PackageConfig.GLUCOSE_BOARD_MODULE_PATH);
        GlucoseBoard.ExtensionLoader.add_search_path ("src/modules/abbott");

        GLib.MainLoop loop = new GLib.MainLoop(null, false);

        //DaemonLogger logger = new DaemonLogger (daemon);
        //Log.set_default_logger (logger);

        GLib.Bus.own_name (GLib.BusType.SYSTEM, "org.freedesktop.GlucoseBoard",
                           GLib.BusNameOwnerFlags.NONE,
                           (conn) => {
                                try
                                {
                                    conn.register_object ("/org/freedesktop/GlucoseBoard", new Daemon (conn));
                                }
                                catch (GLib.IOError e)
                                {
                                    GlucoseBoard.Log.error ("Could not register service");
                                    loop.quit ();
                                }
                           },
                           () => {},
                           () => {
                               GlucoseBoard.Log.error ("Could not aquire name");
                               loop.quit ();
                           });

        loop.run();

        Log.debug_mc ("daemon", "main", "end");

        return 0;
    }
}
