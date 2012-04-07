/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * extension-loader.vala
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
    /**
     * This class manage a list of extension loading
     */
    public class ExtensionLoader<V> : GLib.Object
    {
        // types
        /**
         * Callback function for extension iteration
         *
         * @param inExtension The current extension in loader list
         *
         * @return ``false`` to stop iteration, ``true`` to continue
         */
        public delegate bool ForeachExtensionFunc (Extension inExtension);

        public class Iterator<V> : GLib.Object
        {
            // properties
            private ExtensionLoader<V> m_Loader;
            private int m_Index;

            // methods
            internal Iterator (ExtensionLoader<V> inLoader)
            {
                m_Loader = inLoader;
                m_Index = -1;
            }

            /**
             * Advances to the next extension in the loader list.
             *
             * @return ``true`` if the iterator has a next extension
             */
            public bool
            next ()
            {
                bool ret = false;
                if (m_Index == -1 && m_Loader.m_Extensions.length > 0)
                {
                    m_Index = 0;
                    ret = true;
                }
                else if (++m_Index < m_Loader.m_Extensions.length)
                {
                    ret = true;
                }

                return ret;
            }

            /**
             * Returns the current extension in the loader list.
             *
             * @return the current extension in the loader list
             */
            public new unowned Extension?
            get ()
            {
                return m_Loader.m_Extensions[m_Index];
            }

            /**
             * Calls inFunc for each extension in the loader list.
             *
             * @param inFunc the function to call for each extension
             */
            public void
            @foreach (ForeachExtensionFunc inFunc)
            {
                if (m_Index == -1 && m_Loader.m_Extensions.length > 0)
                {
                    m_Index = 0;
                }
                for (;m_Index < m_Loader.m_Extensions.length; ++m_Index)
                {
                    if (!inFunc (m_Loader.m_Extensions[m_Index]))
                        return;
                }
            }
        }

        // static properties
        private static GLib.List<string> s_ExtensionPath = new GLib.List<string> ();

        // properties
        private Extension[] m_Extensions;

        // accessors
        /**
         * The number of extension in the loader list
         */
        public uint length {
            get {
                return m_Extensions.length;
            }
        }

        // static methods
        /**
         * Add extension module search path
         *
         * @param inPath extension module path
         */
        public static void
        add_search_path (string inPath)
        {
            s_ExtensionPath.prepend (inPath);
        }

        // methods
        /**
         * This class provides the loading of extension module
         */
        public ExtensionLoader ()
        {
            m_Extensions = {};

            foreach (unowned string path in s_ExtensionPath)
            {
                try
                {
                    GLib.Dir dir = GLib.Dir.open (path);
                    if (dir == null)
                    {
                        continue;
                    }

                    for (unowned string file = dir.read_name (); file != null; file = dir.read_name ())
                    {
                        if (GLib.PatternSpec.match_simple ("*.module", file))
                        {
                            try
                            {
                                m_Extensions += new Extension<V> (path + "/" + file);
                            }
                            catch (ExtensionError err)
                            {
                                Log.error ("Error on loading extension %s: %s", file, err.message);
                            }
                        }
                    }
                }
                catch (GLib.FileError err)
                {
                    Log.error ("Error on open extension directory %s: %s", path, err.message);
                }
            }
        }

        /**
         * Returns a {@link Iterator} that can be used for simple iteration over the
         * extension loader list.
         *
         * @return a {@link Iterator} that can be used for simple iteration over the
         *         extension loader list
         */
        public Iterator<V>
        iterator ()
        {
            return new Iterator<V> (this);
        }
    }
}
