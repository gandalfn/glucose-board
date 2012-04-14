/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * ti-3410-stream.vala
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
    public class TI3410Stream : UsbStreamSerial
    {
        // types
        private enum Commands
        {
            GET_VERSION       = 0x01,
            GET_PORT_STATUS   = 0x02,
            GET_PORT_DEV_INFO = 0x03,
            GET_CONFIG        = 0x04,
            SET_CONFIG        = 0x05,
            OPEN_PORT         = 0x06,
            CLOSE_PORT        = 0x07,
            START_PORT        = 0x08,
            STOP_PORT         = 0x09,
            TEST_PORT         = 0x0A,
            PURGE_PORT        = 0x0B,
            RESET_EXT_DEVICE  = 0x0C,
            WRITE_DATA        = 0x80,
            READ_DATA         = 0x81,
            REQ_TYPE_CLASS    = 0x82
        }

        private enum Port
        {
            I2C      = 0x01,
            IEEE1284 = 0x02,
            UART1    = 0x03,
            UART2    = 0x04,
            RAM      = 0x05
        }

        private struct UARTConfig
        {
            uint16 baud_rate;
            uint16 flags;
            uint8 data_bits;
            uint8 parity;
            uint8 stop_bits;
            uint8 xon;
            uint8 xoff;
            uint8 mode;
        }

        private enum UARTFlags
        {
            ENABLE_RTS_IN           = 0x0001,
            DISABLE_RTS             = 0x0002,
            ENABLE_PARITY_CHECKING  = 0x0008,
            ENABLE_DSR_OUT          = 0x0010,
            ENABLE_CTS_OUT          = 0x0020,
            ENABLE_X_OUT            = 0x0040,
            ENABLE_XA_OUT           = 0x0080,
            ENABLE_X_IN             = 0x0100,
            ENABLE_DTR_IN           = 0x0800,
            DISABLE_DTR             = 0x1000,
            ENABLE_MS_INTS          = 0x2000,
            ENABLE_AUTO_START_DMA   = 0x4000
        }

        private enum UARTParity
        {
            NO_PARITY    = 0x00,
            ODD_PARITY   = 0x01,
            EVEN_PARITY  = 0x02,
            MARK_PARITY  = 0x03,
            SPACE_PARITY = 0x04
        }

        private enum UARTData
        {
            5_BITS = 0x00,
            6_BITS = 0x01,
            7_BITS = 0x02,
            8_BITS = 0x03
        }

        private enum UARTStopBit
        {
            1_BITS   = 0x00,
            1_5_BITS = 0x01,
            2_BITS   = 0x02
        }

        private enum UARTMcr
        {
            LOOP = 0x04,
            DTR  = 0x10,
            RTS  = 0x20
        }

        /**
         * Create new TI3410 stream serial for inDevice
         *
         * @param inDevice usb device to create stream for
         * @param inInterfaceNumber the usb device interface number
         * @param inEndPointRead the usb device interface end point read
         */
        public TI3410Stream (UsbDevice inDevice, uint inInterfaceNumber, uint inEndPointRead, uint inEndPointWrite)
        {
            // Launch base constructor
            base (inDevice, inInterfaceNumber, inEndPointRead, inEndPointWrite);
        }

        /**
         * Load TI3410 firmware
         *
         * @param inFilename firmware filename
         *
         * @throw StreamError when something goes wrong
         */
        public void
        load_firmware (string inFilename) throws StreamError
        {
            base.open ();

            try
            {
                Log.info ("TI3410 load firmware %s", inFilename);

                // Get firmware content
                GLib.MappedFile firmware = new GLib.MappedFile (inFilename, false);

                // Load firmware
                size_t size = firmware.get_length ();
                uint8* ptr = firmware.get_contents ();
                bool first = true;
                uint8 checksum = 0;

                // Calculate checksum
                for (int cpt = 0; cpt < size; ++cpt)
                {
                    checksum += ptr[cpt];
                }

                while (size > 0)
                {
                    // First frame
                    if (first)
                    {
                        Log.debug ("Firmware header 0x%04x 0x%02x", LibUSB.cpu_to_le16 ((uint16)size), checksum);
                        Message msg = new Message (write_max_packet_size);
                        msg.set_uint16 (0, LibUSB.cpu_to_le16 ((uint16)size));
                        msg[2] = checksum;
                        msg.set_array (3, (uint8[])ptr, write_max_packet_size - 3);
                        size -= write_max_packet_size - 3;
                        ptr = ptr + write_max_packet_size - 3;
                        send (msg, 1000);
                        first = false;
                    }
                    else
                    {
                        size_t n = size >= write_max_packet_size ? write_max_packet_size : size;
                        Message msg = new Message ((uint)n);
                        msg.set_array (0, (uint8[])ptr, (uint)n);
                        send (msg, 1000);
                        size -= n;
                        ptr = ptr + n;
                    }
                }

                // Reset device
                reset ();
            }
            catch (GLib.Error err)
            {
                base.close ();
                throw new StreamError.WRITE ("Error on loading firmware %s: %s", inFilename, err.message);
            }

            base.close ();
        }

        public override void
        configure (UsbStreamSerial.Config inConfig) throws StreamError
        {
            UARTConfig config = UARTConfig ();

            // these flags must be set
            config.flags = UARTFlags.ENABLE_MS_INTS | UARTFlags.ENABLE_AUTO_START_DMA;

            // use rs232
            config.mode = 0;

            // set baud rate
            config.baud_rate = (uint16)(14769230.77 / (inConfig.baud_rate * 16));

            // set data bits
            switch (inConfig.bits)
            {
                case 5:
                    config.data_bits = UARTData.5_BITS;
                    break;
                case 6:
                    config.data_bits = UARTData.6_BITS;
                    break;
                case 7:
                    config.data_bits = UARTData.7_BITS;
                    break;
                case 8:
                    config.data_bits = UARTData.8_BITS;
                    break;
            }

            // set parity
            switch (inConfig.parity)
            {
                case Parity.NONE:
                    config.flags &= ~UARTFlags.ENABLE_PARITY_CHECKING;
                    config.parity = UARTParity.NO_PARITY;
                    break;
                case Parity.ODD:
                    config.flags |= UARTFlags.ENABLE_PARITY_CHECKING;
                    config.parity = UARTParity.ODD_PARITY;
                    break;
                case Parity.EVEN:
                    config.flags |= UARTFlags.ENABLE_PARITY_CHECKING;
                    config.parity = UARTParity.EVEN_PARITY;
                    break;
            }

            // set stop bits
            if (inConfig.stop_bits == 2)
                config.stop_bits = UARTStopBit.2_BITS;
            else
                config.stop_bits = UARTStopBit.1_BITS;

            // set xon/xoff
            config.xon = 0x11;
            config.xoff = 0x13;
            if (inConfig.xonxoff)
            {
                config.flags |= UARTFlags.ENABLE_X_IN;
                config.flags |= UARTFlags.ENABLE_X_OUT;
            }

            // set message
            var msg = new Message (10);
            msg[0] = (uint8)(config.baud_rate >> 8);
            msg[1] = (uint8)config.baud_rate;
            msg[2] = (uint8)(config.flags >> 8);
            msg[3] = (uint8)config.flags;
            msg[4] = config.data_bits;
            msg[5] = config.parity;
            msg[6] = config.stop_bits;
            msg[7] = config.xon;
            msg[8] = config.xoff;
            msg[9] = config.mode;

            // send message
            uint8[] data = msg.raw;
            Log.debug ("send serial configuration: %s", msg.to_string ());
            send_control_message (LibUSB.RequestType.VENDOR | LibUSB.RequestRecipient.DEVICE | LibUSB.EndpointDirection.OUT,
                                  Commands.SET_CONFIG, 0, Port.UART1, ref data);
        }
    }
}
