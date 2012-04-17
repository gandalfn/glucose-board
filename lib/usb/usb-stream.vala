/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * usb-stream.vala
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
     * Usb stream device implementation
     */
    public class UsbStream : Stream
    {
        // properties
        private UsbDevice            m_Device;
        private uint                 m_Interface;
        private uint                 m_EndPointRead;
        private uint                 m_EndPointWrite;
        private uint8                m_ConfigurationValue;
        private bool                 m_ReadEndPointAvailable;
        private LibUSB.TransferType  m_ReadTransferType;
        private uint                 m_ReadMaxPacketSize;
        private bool                 m_WriteEndPointAvailable;
        private LibUSB.TransferType  m_WriteTransferType;
        private uint                 m_WriteMaxPacketSize;
        private LibUSB.DeviceHandle? m_Handle = null;

        // accessors
        public bool read_ep_available {
            get {
                return m_ReadEndPointAvailable;
            }
        }

        public bool write_ep_available {
            get {
                return m_WriteEndPointAvailable;
            }
        }

        public uint read_max_packet_size {
            get {
                return m_ReadMaxPacketSize;
            }
        }

        public uint write_max_packet_size {
            get {
                return m_WriteMaxPacketSize;
            }
        }

        public uint8 configuration_value {
            get {
                return m_ConfigurationValue;
            }
            set {
                if (m_Handle != null)
                    m_Handle.set_configuration (value);
            }
        }

        // methods
        /**
         * Create new usb stream for inDevice
         *
         * @param inDevice usb device to create stream for
         * @param inInterfaceNumber the usb device interface number
         * @param inEndPointRead the usb device interface end point read
         */
        public UsbStream (UsbDevice inDevice, uint inInterfaceNumber, uint inEndPointRead, uint inEndPointWrite)
        {
            // Set properties
            m_Device = inDevice;
            m_Interface = inInterfaceNumber;
            m_EndPointRead = inEndPointRead;
            m_EndPointWrite = inEndPointWrite;

            // Get transfer type
            LibUSB.ConfigDescriptor config;
            int status = m_Device.usb_device.get_active_config_descriptor (out config);
            if (status == LibUSB.Error.SUCCESS)
            {
                bool found_interface = false;
                m_ReadEndPointAvailable = false;
                m_WriteEndPointAvailable = false;
                m_ConfigurationValue = config.bConfigurationValue;

                // Search interface
                for (int cpt = 0; cpt < config.bNumInterfaces; ++cpt)
                {
                    foreach (LibUSB.InterfaceDescriptor descriptor in config.interface[cpt].altsetting)
                    {
                        if (descriptor.bInterfaceNumber == m_Interface)
                        {
                            found_interface = true;
                            GlucoseBoard.Log.debug ("Found interface %u: %s",
                                                    m_Interface, inDevice.path);

                            // Search interface end points
                            for (int n = 0; n < descriptor.bNumEndpoints; ++n)
                            {
                                if (descriptor.endpoint[n].bEndpointAddress == m_EndPointRead)
                                {
                                    m_ReadTransferType = (LibUSB.TransferType)(descriptor.endpoint[n].bmAttributes & ((1 << 2) - 1));
                                    m_ReadMaxPacketSize = descriptor.endpoint[n].wMaxPacketSize;
                                    m_ReadEndPointAvailable = true;
                                }

                                if (descriptor.endpoint[n].bEndpointAddress == m_EndPointWrite)
                                {
                                    m_WriteTransferType = (LibUSB.TransferType)(descriptor.endpoint[n].bmAttributes & ((1 << 2) - 1));
                                    m_WriteMaxPacketSize = descriptor.endpoint[n].wMaxPacketSize;
                                    m_WriteEndPointAvailable = true;
                                }
                            }
                        }
                    }
                }

                if (!found_interface)
                    GlucoseBoard.Log.error ("Could not found interface %u for %s",
                                            m_Interface, inDevice.path);

                if (!m_ReadEndPointAvailable)
                    GlucoseBoard.Log.error ("Could not found read end point %u.%u for %s",
                                            m_Interface, m_EndPointRead, inDevice.path);

                if (!m_WriteEndPointAvailable)
                    GlucoseBoard.Log.error ("Could not found write end point %u.%u for %s",
                                            m_Interface, m_EndPointWrite, inDevice.path);
            }
            else
                GlucoseBoard.Log.error ("Error on get USB config descriptor for %s: %s",
                                        inDevice.path, UsbDevice.usb_error_to_string (status));
        }

        /**
         * {@inheritDoc}
         */
        public override void
        open () throws StreamError
        {
            if (UsbDevice.s_Context == null)
                throw new StreamError.NOT_INITIALIZED ("cannot open UsbDevice when USB library has not been initialised.");

            if (m_Device.usb_device == null)
                throw new StreamError.INVALID_DEVICE ("invalid device");

            if (is_open)
                throw new StreamError.ALREADY_OPEN ("cannot open already opened %s", m_Device.path);

            // Create usb device handle
            m_Device.usb_device.open (out m_Handle);

            // Claim usb device handle
            int ret;
            int retries = 1000;

            while ((ret = m_Handle.claim_interface ((int)m_Interface)) != 0 && retries-- > 0)
            {
                int status = m_Handle.detach_kernel_driver ((int)m_Interface);
                if (status != LibUSB.Error.SUCCESS)
                    throw new StreamError.OPEN_DEVICE ("failed to detach kernel driver from USB device %s interface %u: %s",
                                                       m_Device.path, m_Interface, UsbDevice.usb_error_to_string (status));
            }

            if (ret != 0)
            {
                m_Handle = null;
                throw new StreamError.OPEN_DEVICE ("failed to claim USB device %s", m_Device.path);
            }

            // Call base method notification
            on_opened ();
        }

        /**
         * {@inheritDoc}
         */
        public override void
        close () throws StreamError
        {
            if (!is_open)
                throw new StreamError.NOT_OPENED ("cannot close already closed %s", m_Device.path);

            // Unset usb device handle
            m_Handle = null;

            // Call base method notification
            on_closed ();
        }

        /**
         * Reset usb device
         */
        public void
        reset ()
        {
            m_Handle.reset ();
        }

        /**
         * Clear the halt/stall condition for read endpoint.
         */
        public void
        clear_halt_read_ep ()
        {
            m_Handle.clear_halt ((uint8)m_EndPointRead);
        }

        /**
         * Clear the halt/stall condition for write endpoint.
         */
        public void
        clear_halt_write_ep ()
        {
            m_Handle.clear_halt ((uint8)m_EndPointWrite);
        }

        /**
         * Send control message
         *
         * @param inType request type
         * @param inRequest request
         * @param inValue request value
         * @param inIndex request index
         * @param outData request data
         *
         * @throw StreamError if something goes wrong
         */
        public void
        send_control_message (uint8 inType, uint8 inRequest, uint16 inValue, uint16 inIndex, ref uint8[]? outData) throws StreamError
        {
            if (!is_open)
                throw new StreamError.NOT_OPENED ("the device %s has not been opened.", m_Device.path);

            GlucoseBoard.Log.debug ("Send control message 0x%x 0x%x 0x%x to usb device %s",
                                    inRequest, inValue, inIndex, m_Device.path);

            int status = m_Handle.control_transfer (inType, inRequest, inValue, inIndex,
                                                    outData != null ? outData : null,
                                                    outData != null ? (uint16)outData.length : 0, 1000);
            if (status < LibUSB.Error.SUCCESS)
            {
                throw new StreamError.WRITE ("Error on send control on %s %u %u: %s", m_Device.path, m_Interface, m_EndPointRead,
                                            UsbDevice.usb_error_to_string (status));
            }
        }

        /**
         * {@inheritDoc}
         */
        protected override void
        read (ref Message inoutMessage, uint inTimeout) throws StreamError
        {
            // warning try to log anything here, this function is launched on seprated thread and dbus does not like send on separated threaded
            if (!is_open)
                throw new StreamError.NOT_OPENED ("the device %s has not been opened.", m_Device.path);

            if (m_ReadTransferType == LibUSB.TransferType.BULK)
            {
                int len;
                int status = m_Handle.bulk_transfer ((uint8)m_EndPointRead, inoutMessage.raw, out len, inTimeout);
                if (status != LibUSB.Error.SUCCESS)
                {
                    throw new StreamError.READ ("Error on read on %s %u %u: %s", m_Device.path, m_Interface, m_EndPointRead,
                                                UsbDevice.usb_error_to_string (status));
                }
            }
            else if (m_ReadTransferType == LibUSB.TransferType.INTERRUPT)
            {
                int len;
                int status = m_Handle.interrupt_transfer ((uint8)m_EndPointRead, inoutMessage.raw, out len, inTimeout);
                if (status != LibUSB.Error.SUCCESS)
                {
                    throw new StreamError.READ ("Error on read on %s %u %u: %s", m_Device.path, m_Interface, m_EndPointRead,
                                                UsbDevice.usb_error_to_string (status));
                }
            }
        }

        /**
         * {@inheritDoc}
         */
        public override void
        send (Message inMessage, uint inTimeout) throws StreamError
        {
            if (!is_open)
                throw new StreamError.NOT_OPENED ("the device %s has not been opened.", m_Device.path);

            GlucoseBoard.Log.debug ("Send %s to usb device %s", inMessage.to_string (), m_Device.path);
            if (m_WriteTransferType == LibUSB.TransferType.BULK)
            {
                int len;
                int status = m_Handle.bulk_transfer ((uint8)m_EndPointWrite, inMessage.raw, out len, inTimeout);
                if (status != LibUSB.Error.SUCCESS)
                {
                    throw new StreamError.WRITE ("Error on send on %s %u %u: %s", m_Device.path, m_Interface, m_EndPointWrite,
                                                 UsbDevice.usb_error_to_string (status));
                }
                GlucoseBoard.Log.debug ("Sent %i to usb device %s", len, m_Device.path);
            }
            else if (m_WriteTransferType == LibUSB.TransferType.INTERRUPT)
            {
                int len;
                int status = m_Handle.interrupt_transfer ((uint8)m_EndPointWrite, inMessage.raw, out len, inTimeout);
                if (status > LibUSB.Error.SUCCESS)
                {
                    throw new StreamError.WRITE ("Error on read on %s %u %u: %s", m_Device.path, m_Interface, m_EndPointWrite,
                                                 UsbDevice.usb_error_to_string (status));
                }
            }
        }
    }
}
