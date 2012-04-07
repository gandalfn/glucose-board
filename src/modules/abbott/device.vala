/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * module.vala
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

namespace GlucoseBoard.Module.Abbott
{
    /**
     * Optium Xceed device
     */
    [DBus (name = "org.freedesktop.GlucoseBoard.Module.Abbott.Device")]
    public class Device : UsbDevice
    {
        // types
        private enum State
        {
            READY = 0,
            ENQ   = 1 << 1,
            MSG   = 1 << 2,

            QUERY_ID     = 1 << 8,
            QUERY_ID_ENQ = QUERY_ID | ENQ,
            QUERY_ID_MSG = QUERY_ID | MSG,

            MASK         = (1 << 8) - 1,
            STEP_MASK    = (1 << 16) - 1 - MASK
        }

        // properties
        private GLib.DBusConnection m_Connection;
        private string              m_DBusName = "/org/freedesktop/GlucoseBoard/Module/Abbott/Device";
        private uint                m_RegistrationId;
        private int                 m_Index;

        private Config              m_Config;
        private uint                m_UsbInterface;
        private uint                m_UsbEndPointRead;
        private uint                m_UsbEndPointWrite;
        private string              m_Firmware;

        private State               m_State = State.READY;
        private int                 m_Opened = 0;
        private Stream              m_Stream = null;

        // accessors
        /**
         * DBus device object path name
         */
        public string dbus_name {
            get {
                return m_DBusName;
            }
        }

        // methods
        construct
        {
            Log.debug_mc ("abboot", "device", "Create abbott meter device");

            try
            {
                m_Config = new Config ("abbott.conf");

                // Get usb communication parameters
                m_UsbInterface = (uint)m_Config.get_integer_hex (name, "Interface");
                m_UsbEndPointRead = (uint)m_Config.get_integer_hex (name, "EndPointRead");
                m_UsbEndPointWrite = (uint)m_Config.get_integer_hex (name, "EndPointWrite");
                m_Firmware = m_Config.get_string (name, "Firmware");
            }
            catch (GLib.Error err)
            {
                Log.critical_mc ("abbott", "device", "Error on reading config: %s", err.message);
            }
        }

        ~Device ()
        {
            Log.debug_mc ("abbott", "device", GLib.Log.METHOD);
            unregister ();
        }

        private void
        open_stream ()
        {
            Log.debug_mc ("abbott", "device", GLib.Log.METHOD);

            // Create blood meter communication stream
            if (m_Stream == null)
            {
                try
                {
                    m_Stream = create_stream (m_UsbInterface, m_UsbEndPointRead, m_UsbEndPointWrite);
                    m_Stream.open ();
                    m_Opened = 1;
                }
                catch (StreamError err)
                {
                    Log.critical_mc ("abbott", "device", "Error on open stream communication with blood meter: %s", err.message);
                }
            }
            else
            {
                m_Opened++;
            }

            Log.debug_mc ("abbott", "device", "Open stream %i", m_Opened);
        }

        private void
        close_stream ()
        {
            Log.debug_mc ("abbott", "device", GLib.Log.METHOD);

            if (m_Stream != null)
            {
                Log.debug_mc ("abbott", "device", "Close stream %i", m_Opened);
                if (m_Opened == 1)
                {
                    try
                    {
                        m_Stream.close ();
                    }
                    catch (StreamError err)
                    {
                        Log.critical_mc ("abbott", "device", "Error on close stream communication with blood meter: %s", err.message);
                    }
                    m_Stream = null;
                    m_Opened = 0;
                }
                else
                {
                    m_Opened--;
                }
            }
        }

        private void
        on_wait_ack ()
        {
            try
            {
                Message message = (Message)m_Stream.pop ();
                if (message.is_ack)
                {
                    switch (m_State & State.STEP_MASK)
                    {
                        case State.QUERY_ID:
                            on_ack_query_id ();
                            break;
                    }
                }
                else
                {
                    Log.warning_mc ("abbott", "device", "Received 0x%x", message.raw[0]);
                }
            }
            catch (StreamError err)
            {
                Log.critical_mc ("abbott", "device", err.message);
            }
        }

        private void
        on_ack_query_id ()
        {
            try
            {
                switch (m_State & State.MASK)
                {
                    case State.ENQ:
                        m_Stream.send (new Message.query_id (), 1000);

                        m_State = State.QUERY_ID | State.MSG;
                        Message msg = new Message ();
                        m_Stream.recv (msg, 1000, on_wait_ack);

                        break;

                    case State.MSG:
                        m_Stream.send (new Message.EOT (), 1000);
                        //Message msg = new Message ();
                        //m_Stream.recv (msg, 1000, on_wait_response);
                        close_stream ();
                        break;
                }
            }
            catch (StreamError err)
            {
                Log.critical_mc ("abbott", "device", err.message);
            }
        }

        internal void
        register (GLib.DBusConnection inConnection, uint inIndex)
        {
            Log.debug_mc ("abbott", "device", GLib.Log.METHOD);

            // Keep connection
            m_Connection = inConnection;
            m_Index = (int)inIndex;

            // register object on dbus
            m_DBusName = m_DBusName + "/" + inIndex.to_string ();
            Log.debug_mc ("abbott", "device", "Register meter %s on dbus", m_DBusName);
            try
            {
                m_RegistrationId = m_Connection.register_object (m_DBusName, this);
            }
            catch (GLib.IOError err)
            {
                Log.error_mc ("abbott", "device", "Error on register %s", m_DBusName);
            }
        }

        internal void
        unregister ()
        {
            Log.debug_mc ("abbott", "device", GLib.Log.METHOD);
            if (m_Connection != null)
            {
                m_Connection.unregister_object (m_RegistrationId);
            }
        }

        public void
        load_firmware ()
        {
            Log.debug_mc ("abbott", "device", GLib.Log.METHOD);

            open_stream ();

            try
            {
                Log.info_mc ("abbott", "device", "load firmware");

                // Get firmware content
                GLib.MappedFile firmware = new GLib.MappedFile (m_Firmware, false);

                // Load firmware
                size_t size = firmware.get_length ();
                uint8* ptr = firmware.get_contents ();
                bool first = true;

                while (size > 0)
                {
                    // First frame
                    if (first)
                    {
                        Message msg = new Message (64);
                        msg[0] = 0x00;
                        msg[1] = 0x38;
                        msg[2] = 0xA1;
                        msg.set_array (3, (uint8[])ptr, 61);
                        size -= 61;
                        ptr = ptr + 61;
                        m_Stream.send (msg, 1000);
                        first = false;
                    }
                    else
                    {
                        size_t n = size >= 64 ? 64 : size;
                        Message msg = new Message ((uint)n);
                        msg.set_array (0, (uint8[])ptr, (uint)n);
                        m_Stream.send (msg, 1000);
                        size -= n;
                        ptr = ptr + n;
                    }
                }
                ((UsbStream)m_Stream).reset ();
            }
            catch (GLib.Error err)
            {
                Log.critical_mc ("abbott", "device", err.message);
            }

            close_stream ();
        }

        public void
        init ()
        {
            Log.debug_mc ("abbott", "device", GLib.Log.METHOD);

            open_stream ();

            try
            {
                Log.info_mc ("abbott", "device", "init");
                //((UsbStream)m_Stream).set_descriptor (0x0000);
                //((UsbStream)m_Stream).set_address (0x8000);
                //m_Stream.send (new Message (), 5000);
                m_Stream.send (new Message.mem (), 5000);
                //((UsbStream)m_Stream).clear_end_point ((uint8)m_UsbEndPointRead);
                //((UsbStream)m_Stream).clear_end_point ((uint8)m_UsbEndPointWrite);
            }
            catch (GLib.Error err)
            {
                Log.critical_mc ("abbott", "device", err.message);
            }

            try
            {
                //m_Stream.send (new Message (), 5000);
                m_Stream.send (new Message.xmem (), 5000);
                //((UsbStream)m_Stream).clear_end_point ((uint8)m_UsbEndPointRead);
                //((UsbStream)m_Stream).clear_end_point ((uint8)m_UsbEndPointWrite);
            }
            catch (GLib.Error err)
            {
                Log.critical_mc ("abbott", "device", err.message);
            }

            close_stream ();
        }

        /**
         * Query blood meter identifier
         */
        public void
        query_id ()
        {
            Log.debug_mc ("abbott", "device", GLib.Log.METHOD);

            try
            {
                Log.info_mc ("abbott", "device", "Query blood meter id");
                open_stream ();
                m_Stream.send (new Message.ENQ (), 1000);

                m_State = State.QUERY_ID_ENQ;
                Message msg = new Message ();
                m_Stream.recv (msg, 1000, on_wait_ack);
            }
            catch (StreamError err)
            {
                Log.critical_mc ("abbott", "device", err.message);
                close_stream ();
            }
        }
    }
}
