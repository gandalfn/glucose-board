/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * usb-device.vala
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
     * This class provides extended information for usb device.
     */
    public class UsbDevice : Device
    {
        // static properties
        internal static LibUSB.Context? s_Context = null;

        // properties
        private unowned LibUSB.Device? m_UsbDevice = null;

        // accessors
        /**
         * {@inheritDoc}
         */
        public override string path { get; construct set; default = null; }

        /**
         * {@inheritDoc}
         */
        public override string name { get; construct set; default = null; }

        /**
         * {@inheritDoc}
         */
        public override uint vendor_id { get; construct set; default = 0xFFFF; }

        /**
         * {@inheritDoc}
         */
        public override uint product_id { get; construct set; default = 0xFFFF; }

        /**
         * LibUSB Device
         */
        internal LibUSB.Device? usb_device {
            get {
                return m_UsbDevice;
            }
        }

        /**
         * Device Release Number
         */
        public uint16 release_number {
            get {
                if (m_UsbDevice != null)
                {
                    LibUSB.DeviceDescriptor descriptor;
                    int status = m_UsbDevice.get_device_descriptor (out descriptor);
                    if (status == LibUSB.Error.SUCCESS)
                        return descriptor.bcdDevice;
                    else
                        GlucoseBoard.Log.error ("failed to get USB device descriptor: %s", usb_error_to_string (status));
                }

                return 0;
            }
        }

        /**
         * Device Serial Number
         */
        public uint16 serial_number {
            get {
                if (m_UsbDevice != null)
                {
                    LibUSB.DeviceDescriptor descriptor;
                    int status = m_UsbDevice.get_device_descriptor (out descriptor);
                    if (status == LibUSB.Error.SUCCESS)
                        return descriptor.iSerialNumber;
                    else
                        GlucoseBoard.Log.error ("failed to get USB device descriptor: %s", usb_error_to_string (status));
                }

                return 0;
            }
        }

        // static methods
        static construct
        {
            // Initialize LibUSB
            if (s_Context == null)
            {
                int status = LibUSB.Context.init (out s_Context);
                if (status != LibUSB.Error.SUCCESS)
                {
                    GlucoseBoard.Log.error ("Error on initialize USB: %s", usb_error_to_string (status));
                }
            }
        }

        internal static string
        usb_error_to_string (int inError)
        {
            switch (inError)
            {
                case LibUSB.Error.SUCCESS:
                    return "Success (no error).";

                case LibUSB.Error.IO:
                    return "Input/output error.";

                case LibUSB.Error.INVALID_PARAM:
                    return "Invalid parameter.";

                case LibUSB.Error.ACCESS:
                    return "Access denied (insufficient permissions).";

                case LibUSB.Error.NO_DEVICE:
                    return "No such device (it may have been disconnected).";

                case LibUSB.Error.NOT_FOUND:
                    return "Entity not found.";

                case LibUSB.Error.BUSY:
                    return "Resource busy.";

                case LibUSB.Error.TIMEOUT:
                    return "Operation timed out.";

                case LibUSB.Error.OVERFLOW:
                    return "Overflow";

                case LibUSB.Error.PIPE:
                    return "Pipe error.";

                case LibUSB.Error.INTERRUPTED:
                    return "System call interrupted (perhaps due to signal).";

                case LibUSB.Error.NO_MEM:
                    return "System call interrupted (perhaps due to signal).";

                case LibUSB.Error.NOT_SUPPORTED:
                    return "Operation not supported or unimplemented on this platform.";

                case LibUSB.Error.OTHER:
                    return "Other error";
            }

            return "Unknown error.";
        }

        // methods
        construct
        {
            // On each device creation we will reparse devices
            GlucoseBoard.Log.debug ("scanning for USB devices...");
            LibUSB.Device[] devices;
            size_t nb_devices = s_Context.get_device_list (out devices);
            if (nb_devices < 0)
                GlucoseBoard.Log.error ("failed to scan for USB devices");

            GlucoseBoard.Log.debug ("enumerating USB devices ...");
            for (int cpt = 0; cpt < nb_devices; ++cpt)
            {
                GlucoseBoard.Log.debug ("inspecting USB device %i...", cpt);

                LibUSB.DeviceDescriptor descriptor;
                int status = devices[cpt].get_device_descriptor (out descriptor);
                if (status == LibUSB.Error.SUCCESS)
                {
                    if (descriptor.idVendor == vendor_id && descriptor.idProduct == product_id)
                    {
                        GlucoseBoard.Log.debug ("found usb device 0x%04x:0x%04x",
                                                descriptor.idVendor, descriptor.idProduct);
                        m_UsbDevice = devices[cpt];
                    }
                }
                else
                {
                    GlucoseBoard.Log.error ("failed to get USB device descriptor: %s", usb_error_to_string (status));
                }
            }

            if (m_UsbDevice == null)
                GlucoseBoard.Log.error ("usb device 0x%04x:0x%04x not found", vendor_id, product_id);
        }

        /**
         * {@inheritDoc}
         */
        public override string
        to_string ()
        {
            string ret = "Device: \n" + path;

            ret += "\tname: \n" + name;
            ret += "\tvendor id: 0x%02x".printf (vendor_id);
            ret += "\tproduct id: 0x%02x".printf (product_id);

            return ret;
        }

        /**
         * {@inheritDoc}
         */
        public override int
        compare (Device inOther)
        {
            uint32 id = (vendor_id << 16) + (product_id & 0x0FFFF);
            uint32 other_id = (inOther.vendor_id << 16) + (inOther.product_id & 0x0FFFF);

            return (int)(id - other_id);
        }
    }
}
