/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * extension.vala
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
    public errordomain ExtensionError
    {
        CREATE,
        LOADING,
        NOT_LOADED,
        CREATE_PLUGIN
    }

    /**
     * This class provides module creation and description
     */
    public class Extension<V> : GLib.Object
    {
        // type
        public delegate GLib.Type PluginInitFunc (GLib.Module inModule);

        // properties
        private GLib.Type   m_Type = GLib.Type.INVALID;
        private GLib.Module m_Module;
        // accessors
        /**
         * The name of the module
         */
        public string name { get; private set; default = null; }

        /**
         * The description of the module
         */
        public string description { get; private set; default = null; }

        /**
         * The module filename
         */
        public string module_filename { get; private set; default = null; }

        /**
         * The dbus interface of the module
         */
        public string dbus_name { get; private set; default = null; }


        // methods
        /**
         * This class provides module creation and description
         *
         * @param inFilename the module description filename
         */
        public Extension (string inFilename) throws ExtensionError
        {
            try
            {
                // Get plugin config file
                Config config = new Config.absolute (inFilename);

                // Get plugin name
                name = config.get_string ("Module", "Name");

                // Get plugin description
                description = config.get_string ("Module", "Description");

                // Get plugin module filename
                module_filename = GLib.Path.get_dirname (inFilename) + "/" + config.get_string ("Module", "Module");

                // Get plugin dbus name
                dbus_name = config.get_string ("Module", "DBus");
            }
            catch (ConfigError err)
            {
                throw new ExtensionError.CREATE ("Error on open %s: %s", inFilename, err.message);
            }
        }

        /**
         * Load the corresponding module
         *
         * @throws ExtensionError raised when something went wrong
         */
        public void
        load () throws ExtensionError
        {
            m_Module = GLib.Module.open (module_filename, GLib.ModuleFlags.BIND_LAZY);
            if (m_Module == null)
            {
                throw new ExtensionError.LOADING ("Error on loading %s: %s", module_filename, m_Module.error ());
            }

            Log.debug ("Loading module %s for extension %s", module_filename, name);

            stdout.printf ("Loaded module: '%s'\n", m_Module.name ());

            void* function;
            if (!m_Module.symbol ("plugin_init", out function))
            {
                throw new ExtensionError.LOADING ("Error on loading %s: %s", module_filename, m_Module.error ());
            }
            unowned PluginInitFunc? plugin_init = (PluginInitFunc?)function;

            m_Type = plugin_init (m_Module);

            Log.debug ("Extension loaded %s: %s", name, m_Type.name ());
        }

        /**
         * Create a object module
         *
         * @param inConnection DBus connection
         *
         * @return Object module
         *
         * @throws ExtensionError raised when something went wrong
         */
        public V
        create (GLib.DBusConnection? inConnection = null) throws ExtensionError
        {
            if (m_Type == GLib.Type.INVALID)
            {
                throw new ExtensionError.NOT_LOADED ("Extension %s not loaded", name);
            }

            DBusModule object = (DBusModule)GLib.Object.new (m_Type, dbus_connection: inConnection);

            if (inConnection != null && dbus_name != "")
            {
                string path = "/" + dbus_name.replace (".", "/");

                try
                {
                    inConnection.register_object (path, object);
                }
                catch (GLib.IOError err)
                {
                    throw new ExtensionError.LOADING ("Error on registering %s: %s", name, err.message);
                }
            }

            return object;
        }
    }
}
