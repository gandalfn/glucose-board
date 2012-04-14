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

            INIT         = 1 << 8,
            QUERY_ID     = 1 << 9,
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
        private TI3410Stream        m_Stream = null;

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

                // Create USB stream
                m_Stream = new TI3410Stream (this, m_UsbInterface, m_UsbEndPointRead, m_UsbEndPointWrite);

                // Read end point is not available load firmware
                if (!m_Stream.read_ep_available)
                {
                    load_firmware ();
                }
                else
                {
                    // Configure stream
                    UsbStreamSerial.Config config = UsbStreamSerial.Config (9600, 8, UsbStreamSerial.Parity.NONE, 1, false);
                    m_Stream.configure (config);

                    // Open stream
                    m_Stream.open ();

                    // Send mem message
                    m_Stream.send (new Message (), 1000);
                    m_Stream.send (new Message.mem (), 1000);

                    // Close stream
                    m_Stream.close ();

                    // Open stream
                    m_Stream.open ();

                    // Send xmem message
                    m_Stream.send (new Message (), 1000);
                    m_Stream.send (new Message.xmem (), 1000);
                }
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
        on_wait_ack ()
        {
            try
            {
                Message message = (Message)m_Stream.pop ();
                if (message.is_ack)
                {
                    switch (m_State & State.STEP_MASK)
                    {
                        case State.INIT:
                            Log.debug_mc ("abbott", "device", "Ack init");
                            m_State = State.READY;
                            break;
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

        /**
         * Load firmware
         */
        internal void
        load_firmware ()
        {
            Log.debug_mc ("abbott", "device", GLib.Log.METHOD);

            try
            {
                Log.info_mc ("abbott", "device", "load firmware");

                m_Stream.load_firmware (m_Firmware);
            }
            catch (GLib.Error err)
            {
                Log.critical_mc ("abbott", "device", err.message);
            }
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
                m_Stream.send (new Message.ENQ (), 1000);

                m_State = State.QUERY_ID_ENQ;
                Message msg = new Message ();
                m_Stream.recv (msg, 1000, on_wait_ack);
            }
            catch (StreamError err)
            {
                Log.critical_mc ("abbott", "device", err.message);
            }
        }
    }
}
