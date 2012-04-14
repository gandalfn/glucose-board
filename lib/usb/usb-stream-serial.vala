/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * usb-stream-serial.vala
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
    public abstract class UsbStreamSerial : UsbStream
    {
        // types
        public enum Parity
        {
            NONE,
            EVEN,
            ODD
        }

        public struct Config
        {
            public uint    baud_rate;
            public uint    bits;
            public Parity  parity;
            public uint    stop_bits;
            public bool    xonxoff;

            public Config (uint inBaudRate, uint inBits, Parity inParity, uint inStopBits, bool inXonXoff)
            {
                baud_rate = inBaudRate;
                bits = inBits;
                parity = inParity;
                stop_bits = inStopBits;
                xonxoff = inXonXoff;
            }
        }

        /**
         * Create new usb stream serial for inDevice
         *
         * @param inDevice usb device to create stream for
         * @param inInterfaceNumber the usb device interface number
         * @param inEndPointRead the usb device interface end point read
         */
        public UsbStreamSerial (UsbDevice inDevice, uint inInterfaceNumber, uint inEndPointRead, uint inEndPointWrite)
        {
            // Launch base constructor
            base (inDevice, inInterfaceNumber, inEndPointRead, inEndPointWrite);
        }

        /**
         * Configure serial communication
         *
         * @param inConfig serial configuration
         *
         * @throw StreamError whene something goes wrong
         */
        public abstract void
        configure (Config inConfig);
    }
}
