/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * log.vala
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

namespace GlucoseBoard.Log
{
    // types
    public enum Level
    {
        ERROR,
        CRITICAL,
        WARNING,
        INFO,
        DEBUG;

        public string
        to_string ()
        {
            switch (this)
            {
                case ERROR:
                    return "[error]";
                case CRITICAL:
                    return "[critical]";
                case WARNING:
                    return "[warning]";
                case INFO:
                    return "[info]";
                case DEBUG:
                    return "[debug]";
            }

            return "";
        }
    }

    /**
     * Log wrapper class
     */
    public abstract class Logger : GLib.Object
    {
        // types
        private enum ConsoleColor
        {
            BLACK   = 0,
            RED     = 1,
            GREEN   = 2,
            YELLOW  = 3,
            BLUE    = 4,
            MAGENTA = 5,
            CYAN    = 6,
            WHITE   = 7;

            public string
            to_string (bool inHighlight = true)
            {
                return "\033[%i;%im".printf (inHighlight ? 1 : 0, this + 30);
            }
        }

        // properties
        private string m_Domain     = "";
        private Level  m_Level      = Level.WARNING;
        private bool   m_Colorized  = false;
        private bool   m_Formatted  = true;

        // accessors
        public Level level {
            get {
                return m_Level;
            }
            construct set {
                m_Level = value;
            }
        }

        public string domain {
            get {
                return m_Domain;
            }
            construct {
                m_Domain = value;
            }
        }

        public bool formatted {
            get {
                return m_Formatted;
            }
            set {
                m_Formatted = value;
            }
        }

        public bool colorized {
            get {
                return m_Colorized;
            }
            set {
                m_Colorized = value;
            }
        }

        // methods
        protected string
        colorize (Level inLevel, string inMessage)
        {
            string prefix = "";
            string postfix = "\033[m";

            switch (inLevel)
            {
                case Level.DEBUG:
                    prefix = ConsoleColor.WHITE.to_string ();
                    break;
                case Level.INFO:
                    prefix = ConsoleColor.GREEN.to_string ();
                    break;
                case Level.WARNING:
                    prefix = ConsoleColor.YELLOW.to_string ();
                    break;
                case Level.CRITICAL:
                    prefix = ConsoleColor.RED.to_string ();
                    break;
                case Level.ERROR:
                    prefix = ConsoleColor.RED.to_string ();
                    break;
                default:
                    prefix = "";
                    postfix = "";
                    break;
            }

            return "%s%s%s".printf (prefix, inMessage, postfix );
        }

        protected string
        format (Level inLevel, string inMessage)
        {
            GLib.TimeVal now = GLib.TimeVal ();
            now.get_current_time ();

            int hour = (int)(now.tv_sec / 3600.0);
            int min = (int)((now.tv_sec / 60.0) - (hour * 60.0));
            int second = (int)(now.tv_sec - (hour * 3600) - (min * 60));

            return "[%.2d:%.2d:%.2d.%.6d] [%s] %s %s".printf ((hour % 24) + 1, min, second, (int)now.tv_usec,
                                                              m_Domain, inLevel.to_string (), inMessage);
        }

        /**
         * Write log trace
         *
         * @param inLevel log level
         * @param inMessage log message
         */
        public inline void
        log (Level inLevel, string inMessage)
        {
            if (inLevel <= m_Level)
            {
                if (m_Formatted)
                {
                    string msg = format (inLevel, inMessage);
                    write (m_Domain, inLevel, msg);
                }
                else
                {
                    write (m_Domain, inLevel, inMessage);
                }
            }
        }

        /**
         * Write log trace with module and category
         *
         * @param inLevel log level
         * @param inModule module name
         * @param inCategory category name
         * @param inMessage log message
         */
        public inline void
        log_mc (Level inLevel, string inModule, string inCategory, string inMessage)
        {
            if (inLevel <= m_Level)
            {
                if (m_Formatted)
                {
                    string msg = format (inLevel, "[%s] [%s] %s".printf (inModule, inCategory, inMessage));
                    write (m_Domain, inLevel, msg);
                }
                else
                {
                    write (m_Domain, inLevel, "[%s] [%s] %s".printf (inModule, inCategory, inMessage));
                }
            }
        }

        /**
         * Write log message, must be implemented by child class
         *
         * @param inDomain log domain
         * @param inLevel log level
         * @param inMessage log message
         */
         public abstract void write (string inDomain, Level inLevel, string inMessage);
    }

    /**
     * description
     */
    public class File : Logger
    {
        // properties
        private int m_Fd;
        private bool m_CloseOnDestroy = true;

        // accessors
        public int fd {
            get {
                return m_Fd;
            }
            construct set {
                m_Fd = value;
            }
        }

        public bool close_on_destroy {
            get {
                return m_CloseOnDestroy;
            }
            construct set {
                m_CloseOnDestroy = value;
            }
        }

        // methods
        ~File ()
        {
            if (m_CloseOnDestroy)
            {
                Posix.close (m_Fd);
            }
        }

        public override void
        write (string inDomain, Level inLevel, string inMessage)
        {
            if (fd > 0)
            {
                string msg = "%s\n".printf (inMessage);
                if (colorized) msg = colorize (inLevel, msg);
                Posix.write (fd, msg, msg.length);

            }
        }
    }

    /**
     * Logger redirected in standard error
     */
    public class Stderr : File
    {
        // methods
        /**
         * Create a new logger redirected in standard error
         *
         * @param inLevel default log level
         * @param inDomain log domain
         */
        public Stderr (Level inLevel, string inDomain = PackageConfig.GLUCOSE_BOARD_NAME)
        {
            GLib.Object (domain: inDomain, level: inLevel, fd: 2, close_on_destroy: false);
            colorized = true;
        }
    }

    /**
     * Logger redirected in kmsg queue
     */
    public class KMsg : File
    {
        // methods
        /**
         * Create a new logger redirected in kmsg queue
         *
         * @param inLevel default log level
         * @param inDomain log domain
         */
        public KMsg (Level inLevel, string inDomain = PackageConfig.GLUCOSE_BOARD_NAME)
        {
            int fd = Posix.open("/dev/kmsg", Posix.O_WRONLY);
            GLib.Object (domain: inDomain, level: inLevel, fd: fd);
        }
    }

    /**
     * Logger redirected in syslog
     */
    public class Syslog : Logger
    {
        // methods
        /**
         * Create a new logger redirected in syslog
         *
         * @param inDomain log domain
         * @param inLevel default log level
         */
        public Syslog (Level inLevel, string inDomain = PackageConfig.GLUCOSE_BOARD_NAME)
        {
            GLib.Object (domain: inDomain, level: inLevel);
        }

        public override void
        write (string inDomain, Level inLevel, string inMessage)
        {
            int level = Posix.LOG_CRIT;

            switch (inLevel)
            {
                case Level.ERROR:
                    level = Posix.LOG_ERR;
                    break;
                case Level.CRITICAL:
                    level = Posix.LOG_CRIT;
                    break;
                case Level.WARNING:
                    level = Posix.LOG_WARNING;
                    break;
                case Level.INFO:
                    level = Posix.LOG_INFO;
                    break;
                case Level.DEBUG:
                    level = Posix.LOG_DEBUG;
                    break;
                default:
                    break;
            }

            Posix.syslog (level, inMessage);
        }
    }

    // static properties
    private static Logger s_Logger = null;

    // static methods
    private static inline string
    remove_filename_line_number (string inMessage)
    {
        char* str = (char*)inMessage.data;
        if (GLib.PatternSpec.match_simple ("*.vala:*:*", inMessage))
        {
            int vala_pos = inMessage.index_of (".vala:");
            str = (char*)inMessage.data + vala_pos + ".vala:".length;
            vala_pos = ((string)str).index_of (": ");
            str = str + vala_pos + ": ".length;
        }
        return (string)str;
    }

    private static void
    glib_log_handler (string? inLogDomain, LogLevelFlags inLogLevels, string inMessage)
    {
        Level level = Level.ERROR;

        switch (inLogLevels)
        {
            case GLib.LogLevelFlags.LEVEL_ERROR:
                level = Level.ERROR;
                break;
            case GLib.LogLevelFlags.LEVEL_CRITICAL:
                level = Level.CRITICAL;
                break;
            case GLib.LogLevelFlags.LEVEL_WARNING:
                level = Level.WARNING;
                break;
            case GLib.LogLevelFlags.LEVEL_MESSAGE:
                level = Level.INFO;
                break;
            case GLib.LogLevelFlags.LEVEL_INFO:
                level = Level.INFO;
                break;
            case GLib.LogLevelFlags.LEVEL_DEBUG:
                level = Level.DEBUG;
                break;
            default:
                break;
        }

        logger ().log (level, remove_filename_line_number (inMessage));
    }

    private static inline unowned Logger?
    logger ()
    {
        if (s_Logger == null)
        {
            s_Logger = new Stderr (Level.WARNING);
            GLib.Log.set_default_handler (glib_log_handler);
        }

        return s_Logger;
    }

    /**
     * Get default logger object
     */
    public static unowned Logger?
    get_default_logger ()
    {
        return s_Logger;
    }

    /**
     * Set default logger object
     */
    public static void
    set_default_logger (Logger inLogger)
    {
        s_Logger = inLogger;
        GLib.Log.set_default_handler (glib_log_handler);
    }

    /**
     * A convenience function to log a debug message.
     *
     * @param inMessage log message
     */
    [PrintfFormat]
    public static void
    debug (string inMessage, ...)
    {
        va_list args = va_list ();
        string msg = inMessage.vprintf (args);
        logger ().log (Level.DEBUG, msg);
    }

    /**
     * A convenience function to log a debug message.
     *
     * @param inModule module name
     * @param inCategory category name
     * @param inMessage log message
     */
    [PrintfFormat]
    public static void
    debug_mc (string inModule, string inCategory, string inMessage, ...)
    {
        va_list args = va_list ();
        string msg = inMessage.vprintf (args);
        logger ().log_mc (Level.DEBUG, inModule, inCategory, msg);
    }

    /**
     * A convenience function to log a info message.
     *
     * @param inMessage log message
     */
    [PrintfFormat]
    public static void
    info (string inMessage, ...)
    {
        va_list args = va_list ();
        string msg = inMessage.vprintf (args);
        logger ().log (Level.INFO, msg);
    }

    /**
     * A convenience function to log a info message.
     *
     * @param inModule module name
     * @param inCategory category name
     * @param inMessage log message
     */
    [PrintfFormat]
    public static void
    info_mc (string inModule, string inCategory, string inMessage, ...)
    {
        va_list args = va_list ();
        string msg = inMessage.vprintf (args);
        logger ().log_mc (Level.INFO, inModule, inCategory, msg);
    }

    /**
     * A convenience function to log a warning message.
     *
     * @param inMessage log message
     */
    [PrintfFormat]
    public static void
    warning (string inMessage, ...)
    {
        va_list args = va_list ();
        string msg = inMessage.vprintf (args);
        logger ().log (Level.WARNING, msg);
    }

    /**
     * A convenience function to log a warning message.
     *
     * @param inModule module name
     * @param inCategory category name
     * @param inMessage log message
     */
    [PrintfFormat]
    public static void
    warning_mc (string inModule, string inCategory, string inMessage, ...)
    {
        va_list args = va_list ();
        string msg = inMessage.vprintf (args);
        logger ().log_mc (Level.WARNING, inModule, inCategory, msg);
    }

    /**
     * A convenience function to log a critical message.
     *
     * @param inMessage log message
     */
    [PrintfFormat]
    public static void
    critical (string inMessage, ...)
    {
        va_list args = va_list ();
        string msg = inMessage.vprintf (args);
        logger ().log (Level.CRITICAL, msg);
    }

    /**
     * A convenience function to log a critical message.
     *
     * @param inModule module name
     * @param inCategory category name
     * @param inMessage log message
     */
    [PrintfFormat]
    public static void
    critical_mc (string inModule, string inCategory, string inMessage, ...)
    {
        va_list args = va_list ();
        string msg = inMessage.vprintf (args);
        logger ().log_mc (Level.CRITICAL, inModule, inCategory, msg);
    }

    /**
     * A convenience function to log a error message.
     *
     * @param inMessage log message
     */
    [PrintfFormat]
    public static void
    error (string inMessage, ...)
    {
        va_list args = va_list ();
        string msg = inMessage.vprintf (args);
        logger ().log (Level.ERROR, msg);
    }

    /**
     * A convenience function to log a error message.
     *
     * @param inModule module name
     * @param inCategory category name
     * @param inMessage log message
     */
    [PrintfFormat]
    public static void
    error_mc (string inModule, string inCategory, string inMessage, ...)
    {
        va_list args = va_list ();
        string msg = inMessage.vprintf (args);
        logger ().log_mc (Level.ERROR, inModule, inCategory, msg);
    }
}
