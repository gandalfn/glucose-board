/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * config.vala
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
    public errordomain ConfigError
    {
        SCHEMA,
        OPEN,
        LOADING,
        GET_VALUE,
        SET_VALUE,
        SAVE,
        REMOVE
    }

    /**
     * This class provides configuration file management
     */
    public class Config : GLib.Object
    {
        // properties
        private string m_Filename;
        private GLib.KeyFile m_KeyFile;
        private GLib.File m_File;
        private GLib.FileMonitor m_MonitorFile;

        // methods
        /**
         * Create configuration file management object
         *
         * @param inFilename configuration filename
         *
         * @throws ConfigError raised when something went wrong
         */
        public Config (string inFilename) throws ConfigError
        {
            string ro_filename = PackageConfig.GLUCOSE_BOARD_CONFIG_PATH + "/" + inFilename;
            string rw_filename = PackageConfig.GLUCOSE_BOARD_STATE_PATH + "/" + inFilename;

            try
            {
                m_File = GLib.File.new_for_path (rw_filename);
                m_MonitorFile = m_File.monitor_file (GLib.FileMonitorFlags.NONE);
                m_MonitorFile.changed.connect (on_config_file_changed);
            }
            catch (GLib.IOError err)
            {
                throw new ConfigError.OPEN ("Error on create file monitoring on %s: %s", rw_filename, err.message);
            }

            // Check config filename
            if (!GLib.FileUtils.test (ro_filename, GLib.FileTest.EXISTS | GLib.FileTest.IS_REGULAR))
            {
                throw new ConfigError.OPEN ("Invalid config filename %s".printf (ro_filename));
            }

            // Check for saved config filename
            m_Filename = ro_filename;
            if (GLib.FileUtils.test (rw_filename, GLib.FileTest.EXISTS | GLib.FileTest.IS_REGULAR))
                m_Filename = rw_filename;

            // Create keyfile
            m_KeyFile = new GLib.KeyFile ();
            m_KeyFile.set_list_separator (',');

            // Load config file
            try
            {
                if (!m_KeyFile.load_from_file (m_Filename, GLib.KeyFileFlags.KEEP_COMMENTS))
                {
                    throw new ConfigError.LOADING ("Error on loading %s".printf (m_Filename));
                }
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.LOADING ("Error on loading %s: %s".printf (m_Filename, err.message));
            }
            catch (GLib.FileError err)
            {
                throw new ConfigError.LOADING ("Error on loading %s: %s".printf (m_Filename, err.message));
            }

            // Set filename to rw directory
            m_Filename = rw_filename;
        }

        /**
         * Create configuration file management object. The absolute configuration cannot be saved
         *
         * @param inFilename absolute configuration filename
         *
         * @throws ConfigError raised when something went wrong
         */
        public Config.absolute (string inFilename) throws ConfigError
        {
            // Check config filename
            if (!GLib.FileUtils.test (inFilename, GLib.FileTest.EXISTS | GLib.FileTest.IS_REGULAR))
            {
                throw new ConfigError.OPEN ("Invalid config filename %s".printf (inFilename));
            }

            // Create keyfile
            m_KeyFile = new GLib.KeyFile ();
            m_KeyFile.set_list_separator (',');

            // Load config file
            m_Filename = inFilename;
            try
            {
                if (!m_KeyFile.load_from_file (m_Filename, GLib.KeyFileFlags.KEEP_COMMENTS))
                {
                    throw new ConfigError.LOADING ("Error on loading %s".printf (m_Filename));
                }
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.LOADING ("Error on loading %s: %s".printf (m_Filename, err.message));
            }
            catch (GLib.FileError err)
            {
                throw new ConfigError.LOADING ("Error on loading %s: %s".printf (m_Filename, err.message));
            }
        }

        private void
        on_config_file_changed (GLib.File inFile, GLib.File? inOtherFile, GLib.FileMonitorEvent inEvent)
        {
            switch (inEvent)
            {
                case GLib.FileMonitorEvent.CREATED:
                case GLib.FileMonitorEvent.CHANGED:
                    // Create keyfile
                    m_KeyFile = new GLib.KeyFile ();
                    m_KeyFile.set_list_separator (',');

                    // Load config file
                    try
                    {
                        if (!m_KeyFile.load_from_file (m_Filename, GLib.KeyFileFlags.KEEP_COMMENTS))
                        {
                            Log.critical ("Error on loading %s", m_Filename);
                        }
                        Log.debug ("%s changed or created reload settings", m_Filename);
                    }
                    catch (GLib.KeyFileError err)
                    {
                        Log.critical ("Error on loading %s: %s", m_Filename, err.message);
                    }
                    catch (GLib.FileError err)
                    {
                        Log.critical ("Error on loading %s: %s", m_Filename, err.message);
                    }
                    break;
            }
        }

        /**
         * Save configuration file
         *
         * @throws ConfigError raised when something went wrong
         **/
        public void
        save () throws ConfigError
        {
            string dir = GLib.Path.get_dirname (m_Filename);
            if (!GLib.FileUtils.test (dir, GLib.FileTest.EXISTS))
            {
                if (GLib.DirUtils.create_with_parents (dir, 0755) != 0)
                    throw new ConfigError.SAVE ("Error on create destination directory %s", dir);
            }

            try
            {
                GLib.FileUtils.set_contents (m_Filename, m_KeyFile.to_data ());
            }
            catch (GLib.FileError err)
            {
                throw new ConfigError.SAVE ("Error on save configuration in %s: %s", m_Filename, err.message);
            }
        }

        /**
         * Returns the boolean value associated with inKey under inSection.
         *
         * @param inSection section name
         * @param inKey key name
         *
         * @return the boolean value associated to inKey under inSection
         *
         * @throws ConfigError raised when something went wrong
         */
        public bool
        get_boolean (string inSection, string inKey) throws ConfigError
        {
            try
            {
                return m_KeyFile.get_boolean (inSection, inKey);
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.GET_VALUE ("Error on get_value [%s] %s: %s".printf (inSection, inKey, err.message));
            }
        }

        /**
         * Associates a new boolean value with inKey under inSection. If key
         * cannot be found then it is created.
         *
         * @param inSection section name
         * @param inKey key name
         * @param inValue new value
         */
        public void
        set_boolean (string inSection, string inKey, bool inValue)
        {
            m_KeyFile.set_boolean (inSection, inKey, inValue);
        }

        /**
         * Returns the boolean value list associated with inKey under inSection.
         *
         * @param inSection section name
         * @param inKey key name
         *
         * @return the boolean value list associated to inKey under inSection
         *
         * @throws ConfigError raised when something went wrong
         */
        public bool[]
        get_boolean_list (string inSection, string inKey) throws ConfigError
        {
            try
            {
                return m_KeyFile.get_boolean_list (inSection, inKey);
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.GET_VALUE ("Error on get_value [%s] %s: %s".printf (inSection, inKey, err.message));
            }
        }

        /**
         * Associates a list of boolean values with inKey under inSection. If key
         * cannot be found then it is created.
         *
         * @param inSection section name
         * @param inKey key name
         * @param inValue new value
         */
        public void
        set_boolean_list (string inSection, string inKey, bool[] inValue)
        {
            m_KeyFile.set_boolean_list (inSection, inKey, inValue);
        }

        /**
         * Returns the integer value associated with inKey under inSection.
         *
         * @param inSection section name
         * @param inKey key name
         *
         * @return the integer value associated to inKey under inSection
         *
         * @throws ConfigError raised when something went wrong
         */
        public int
        get_integer (string inSection, string inKey) throws ConfigError
        {
            try
            {
                return m_KeyFile.get_integer (inSection, inKey);
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.GET_VALUE ("Error on get_value [%s] %s: %s".printf (inSection, inKey, err.message));
            }
        }

        /**
         * Returns the integer value associated with inKey under inSection.
         *
         * @param inSection section name
         * @param inKey key name
         *
         * @return the integer value associated to inKey under inSection
         *
         * @throws ConfigError raised when something went wrong
         */
        public int
        get_integer_hex (string inSection, string inKey) throws ConfigError
        {
            try
            {
                int val = 0;
                m_KeyFile.get_string (inSection, inKey).scanf ("0x%x", ref val);
                return val;
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.GET_VALUE ("Error on get_value [%s] %s: %s".printf (inSection, inKey, err.message));
            }
        }

        /**
         * Associates a new integer value with inKey under inSection. If key
         * cannot be found then it is created.
         *
         * @param inSection section name
         * @param inKey key name
         * @param inValue new value
         */
        public void
        set_integer (string inSection, string inKey, int inValue)
        {
            m_KeyFile.set_integer (inSection, inKey, inValue);
        }

        /**
         * Returns the integer value list associated with inKey under inSection.
         *
         * @param inSection section name
         * @param inKey key name
         *
         * @return the integer value list associated to inKey under inSection
         *
         * @throws ConfigError raised when something went wrong
         */
        public int[]
        get_integer_list (string inSection, string inKey) throws ConfigError
        {
            try
            {
                return m_KeyFile.get_integer_list (inSection, inKey);
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.GET_VALUE ("Error on get_value [%s] %s: %s".printf (inSection, inKey, err.message));
            }
        }

        /**
         * Returns the integer value list associated with inKey under inSection.
         *
         * @param inSection section name
         * @param inKey key name
         *
         * @return the integer value list associated to inKey under inSection
         *
         * @throws ConfigError raised when something went wrong
         */
        public int[]
        get_integer_hex_list (string inSection, string inKey) throws ConfigError
        {
            try
            {
                int[] ret = {};
                string[] vals = m_KeyFile.get_string_list (inSection, inKey);
                foreach (unowned string val in vals)
                {
                    int v = 0;
                    val.scanf ("0x%x", ref v);
                    ret += v;
                }
                return ret;
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.GET_VALUE ("Error on get_value [%s] %s: %s".printf (inSection, inKey, err.message));
            }
        }

        /**
         * Associates a list of integer values with inKey under inSection. If key
         * cannot be found then it is created.
         *
         * @param inSection section name
         * @param inKey key name
         * @param inValue new value
         */
        public void
        set_integer_list (string inSection, string inKey, int[] inValue)
        {
            m_KeyFile.set_integer_list (inSection, inKey, inValue);
        }

        /**
         * Returns the double value associated with inKey under inSection.
         *
         * @param inSection section name
         * @param inKey key name
         *
         * @return the double value associated to inKey under inSection
         *
         * @throws ConfigError raised when something went wrong
         */
        public double
        get_double (string inSection, string inKey) throws ConfigError
        {
            try
            {
                return m_KeyFile.get_double (inSection, inKey);
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.GET_VALUE ("Error on get_value [%s] %s: %s".printf (inSection, inKey, err.message));
            }
        }

        /**
         * Associates a new double value with inKey under inSection. If key
         * cannot be found then it is created.
         *
         * @param inSection section name
         * @param inKey key name
         * @param inValue new value
         */
        public void
        set_double (string inSection, string inKey, double inValue)
        {
            m_KeyFile.set_double (inSection, inKey, inValue);
        }

        /**
         * Returns the double value list associated with inKey under inSection.
         *
         * @param inSection section name
         * @param inKey key name
         *
         * @return the double value list associated to inKey under inSection
         *
         * @throws ConfigError raised when something went wrong
         */
        public double[]
        get_double_list (string inSection, string inKey) throws ConfigError
        {
            try
            {
                return m_KeyFile.get_double_list (inSection, inKey);
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.GET_VALUE ("Error on get_value [%s] %s: %s".printf (inSection, inKey, err.message));
            }
        }

        /**
         * Associates a list of double values with inKey under inSection. If key
         * cannot be found then it is created.
         *
         * @param inSection section name
         * @param inKey key name
         * @param inValue new value
         */
        public void
        set_double_list (string inSection, string inKey, double[] inValue)
        {
            m_KeyFile.set_double_list (inSection, inKey, inValue);
        }

        /**
         * Returns the string value associated with inKey under inSection.
         *
         * @param inSection section name
         * @param inKey key name
         *
         * @return the string value associated to inKey under inSection
         *
         * @throws ConfigError raised when something went wrong
         */
        public string
        get_string (string inSection, string inKey) throws ConfigError
        {
            try
            {
                return m_KeyFile.get_string (inSection, inKey);
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.GET_VALUE ("Error on get_value [%s] %s: %s".printf (inSection, inKey, err.message));
            }
        }

        /**
         * Associates a new string value with inKey under inSection. If key
         * cannot be found then it is created.
         *
         * @param inSection section name
         * @param inKey key name
         * @param inValue new value
         */
        public void
        set_string (string inSection, string inKey, string inValue)
        {
            m_KeyFile.set_string (inSection, inKey, inValue);
        }

        /**
         * Returns the string value list associated with inKey under inSection.
         *
         * @param inSection section name
         * @param inKey key name
         *
         * @return the string value list associated to inKey under inSection
         *
         * @throws ConfigError raised when something went wrong
         */
        public string[]
        get_string_list (string inSection, string inKey) throws ConfigError
        {
            try
            {
                return m_KeyFile.get_string_list (inSection, inKey);
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.GET_VALUE ("Error on get_value [%s] %s: %s".printf (inSection, inKey, err.message));
            }
        }

        /**
         * Associates a list of string values with inKey under inSection. If key
         * cannot be found then it is created.
         *
         * @param inSection section name
         * @param inKey key name
         * @param inValue new value
         */
        public void
        set_string_list (string inSection, string inKey, string[] inValue)
        {
            m_KeyFile.set_string_list (inSection, inKey, inValue);
        }

        /**
         * Remove a key from config
         *
         * @param inSection section name
         * @param inKey key name
         */
        public void
        remove (string inSection, string inKey) throws ConfigError
        {
            try
            {
                m_KeyFile.remove_key (inSection, inKey);
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.REMOVE ("Error on remove [%s] %s: %s".printf (inSection, inKey, err.message));
            }
        }

        /**
         * Remove a section from config
         *
         * @param inSection section name
         */
        public void
        remove_section (string inSection) throws ConfigError
        {
            try
            {
                m_KeyFile.remove_group (inSection);
            }
            catch (GLib.KeyFileError err)
            {
                throw new ConfigError.REMOVE ("Error on remove [%s]: %s".printf (inSection, err.message));
            }
        }
    }
}
