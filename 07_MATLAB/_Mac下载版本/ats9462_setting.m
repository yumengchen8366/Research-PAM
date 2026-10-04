%---------------------------------------------------------------------------
%
% Copyright (c) 2008-2023 AlazarTech, Inc.
%
% AlazarTech, Inc. licenses this software under specific terms and
% conditions. Use of any of the software or derivatives thereof in any
% product without an AlazarTech digitizer board is strictly prohibited.
%
% AlazarTech, Inc. provides this software AS IS, WITHOUT ANY WARRANTY,
% EXPRESS OR IMPLIED, INCLUDING, WITHOUT LIMITATION, ANY WARRANTY OF
% MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. AlazarTech makes no
% guarantee or representations regarding the use of, or the results of the
% use of, the software and documentation in terms of correctness, accuracy,
% reliability, currentness, or otherwise; and you rely on the software,
% documentation and results solely at your own risk.
%
% IN NO EVENT SHALL ALAZARTECH BE LIABLE FOR ANY LOSS OF USE, LOSS OF
% BUSINESS, LOSS OF PROFITS, INDIRECT, INCIDENTAL, SPECIAL OR CONSEQUENTIAL
% DAMAGES OF ANY KIND. IN NO EVENT SHALL ALAZARTECH'S TOTAL LIABILITY EXCEED
% THE SUM PAID TO ALAZARTECH FOR THE PRODUCT LICENSED HEREUNDER.
%
%---------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Return codes
%--------------------------------------------------------------------------
ApiSuccess                                      = int32(512);
ApiFailed                                       = int32(513);
ApiAccessDenied                                 = int32(514);
ApiDmaChannelUnavailable                        = int32(515);
ApiDmaChannelInvalid                            = int32(516);
ApiDmaChannelTypeError                          = int32(517);
ApiDmaInProgress                                = int32(518);
ApiDmaDone                                      = int32(519);
ApiDmaPaused                                    = int32(520);
ApiDmaNotPaused                                 = int32(521);
ApiDmaCommandInvalid                            = int32(522);
ApiDmaManReady                                  = int32(523);
ApiDmaManNotReady                               = int32(524);
ApiDmaInvalidChannelPriority                    = int32(525);
ApiDmaManCorrupted                              = int32(526);
ApiDmaInvalidElementIndex                       = int32(527);
ApiDmaNoMoreElements                            = int32(528);
ApiDmaSglInvalid                                = int32(529);
ApiDmaSglQueueFull                              = int32(530);
ApiNullParam                                    = int32(531);
ApiInvalidBusIndex                              = int32(532);
ApiUnsupportedFunction                          = int32(533);
ApiInvalidPciSpace                              = int32(534);
ApiInvalidIopSpace                              = int32(535);
ApiInvalidSize                                  = int32(536);
ApiInvalidAddress                               = int32(537);
ApiInvalidAccessType                            = int32(538);
ApiInvalidIndex                                 = int32(539);
ApiMuNotReady                                   = int32(540);
ApiMuFifoEmpty                                  = int32(541);
ApiMuFifoFull                                   = int32(542);
ApiInvalidRegister                              = int32(543);
ApiDoorbellClearFailed                          = int32(544);
ApiInvalidUserPin                               = int32(545);
ApiInvalidUserState                             = int32(546);
ApiEepromNotPresent                             = int32(547);
ApiEepromTypeNotSupported                       = int32(548);
ApiEepromBlank                                  = int32(549);
ApiConfigAccessFailed                           = int32(550);
ApiInvalidDeviceInfo                            = int32(551);
ApiNoActiveDriver                               = int32(552);
ApiInsufficientResources                        = int32(553);
ApiObjectAlreadyAllocated                       = int32(554);
ApiAlreadyInitialized                           = int32(555);
ApiNotInitialized                               = int32(556);
ApiBadConfigRegEndianMode                       = int32(557);
ApiInvalidPowerState                            = int32(558);
ApiPowerDown                                    = int32(559);
ApiFlybyNotSupported                            = int32(560);
ApiNotSupportThisChannel                        = int32(561);
ApiNoAction                                     = int32(562);
ApiHSNotSupported                               = int32(563);
ApiVPDNotSupported                              = int32(564);
ApiVpdNotEnabled                                = int32(565);
ApiNoMoreCap                                    = int32(566);
ApiInvalidOffset                                = int32(567);
ApiBadPinDirection                              = int32(568);
ApiPciTimeout                                   = int32(569);
ApiDmaChannelClosed                             = int32(570);
ApiDmaChannelError                              = int32(571);
ApiInvalidHandle                                = int32(572);
ApiBufferNotReady                               = int32(573);
ApiInvalidData                                  = int32(574);
ApiDoNothing                                    = int32(575);
ApiDmaSglBuildFailed                            = int32(576);
ApiPMNotSupported                               = int32(577);
ApiInvalidDriverVersion                         = int32(578);
ApiWaitTimeout                                  = int32(579);
ApiWaitCanceled                                 = int32(580);
ApiBufferTooSmall                               = int32(581);
ApiBufferOverflow                               = int32(582);
ApiInvalidBuffer                                = int32(583);
ApiInvalidRecordsPerBuffer                      = int32(584);
ApiDmaPending                                   = int32(585);
ApiLockAndProbePagesFailed                      = int32(586);
ApiWaitAbandoned                                = int32(587);
ApiWaitFailed                                   = int32(588);
ApiTransferComplete                             = int32(589);
ApiPllNotLocked                                 = int32(590);
ApiNotSupportedInDualChannelMode                = int32(591);
ApiNotSupportedInQuadChannelMode                = int32(592);
ApiFileIoError                                  = int32(593);
ApiInvalidClockFrequency                        = int32(594);
ApiInvalidSkipTable                             = int32(595);
ApiInvalidDspModule                             = int32(596);
ApiDESOnlySupportedInSingleChannelMode          = int32(597);
ApiInconsistentChannel                          = int32(598);
ApiDspFiniteRecordsPerAcquisition               = int32(599);
ApiNotEnoughNptFooters                          = int32(600);
ApiInvalidNptFooter                             = int32(601);
ApiOCTIgnoreBadClockNotSupported                = int32(602);
%ApiError1                                      = int32(603);
%ApiError2                                      = int32(604);
ApiOCTNoTriggerDetected                         = int32(605);
ApiOCTTriggerTooFast                            = int32(606);
ApiNetworkError                                 = int32(607);
ApiFftSizeTooLarge                              = int32(608);
ApiGPUError                                     = int32(609);
ApiAcquisitionModeOnlySupportedInFifoStreaming  = int32(610);
ApiInterleaveNotSupportedInTraditionalMode      = int32(611);
ApiRecordHeadersNotSupported                    = int32(612);
ApiRecordFootersNotSupported                    = int32(613);
ApiFastBufferLockCountExceeded                  = int32(614);
%--------------------------------------------------------------------------
% Board types
%--------------------------------------------------------------------------
ATS_NONE        = int32(0);
ATS850          = int32(1);
ATS310          = int32(2);
ATS330          = int32(3);
ATS855          = int32(4);
ATS315          = int32(5);
ATS335          = int32(6);
ATS460          = int32(7);
ATS860          = int32(8);
ATS660          = int32(9);
ATS665          = int32(10);
% 我们的显卡
ATS9462         = int32(11);
ATS9870         = int32(13);
ATS9350         = int32(14);
ATS9325         = int32(15);
ATS9440         = int32(16);
ATS9351         = int32(18);
ATS9850         = int32(21);
ATS9625         = int32(22);
ATS9626         = int32(24);
ATS9360         = int32(25);
AXI9870         = int32(26);
ATS9370         = int32(27);
ATS9373         = int32(29);
ATS9416         = int32(30);
ATS9637         = int32(31);
ATS9120         = int32(32);
ATS9371         = int32(33);
ATS9130         = int32(34);
ATS9352         = int32(35);
ATS9453         = int32(36);
ATS9146         = int32(37);
ATS9437         = int32(40);
ATS9618         = int32(41);
ATS9358         = int32(42);
ATS9353         = int32(44);
ATS9872         = int32(45);
ATS9628         = int32(47);
ATS9874         = int32(48);
ATS9182         = int32(52);
ATS9364         = int32(53);
ATS9442         = int32(54);
ATS9428         = int32(57);
ATS_LAST        = int32(58);
%--------------------------------------------------------------------------
% ALAZAR_CAPABILITIES
%--------------------------------------------------------------------------
GET_SERIAL_NUMBER = hex2dec('10000024');
GET_FIRST_CAL_DATE = hex2dec('10000025');
GET_LATEST_CAL_DATE = hex2dec('10000026');
GET_LATEST_TEST_DATE = hex2dec('10000027');
GET_LATEST_CAL_DATE_MONTH = hex2dec('1000002D');
GET_LATEST_CAL_DATE_DAY = hex2dec('1000002E');
GET_LATEST_CAL_DATE_YEAR = hex2dec('1000002F');
GET_BOARD_OPTIONS_LOW = hex2dec('10000037');
GET_BOARD_OPTIONS_HIGH = hex2dec('10000038');
MEMORY_SIZE = hex2dec('1000002A');
ASOPC_TYPE = hex2dec('1000002C');
BOARD_TYPE = hex2dec('1000002B');
GET_PCIE_LINK_SPEED = hex2dec('10000030');
GET_PCIE_LINK_WIDTH = hex2dec('10000031');
GET_MAX_PRETRIGGER_SAMPLES = hex2dec('10000046');
GET_CPF_DEVICE = hex2dec('10000071');
HAS_RECORD_FOOTERS_SUPPORT = hex2dec('10000073');
CAP_SUPPORTS_TRADITIONAL_AUTODMA = hex2dec('10000074');
CAP_SUPPORTS_NPT_AUTODMA = hex2dec('10000075');
CAP_MAX_NPT_PRETRIGGER_SAMPLES = hex2dec('10000076');
CAP_IS_VFIFO_BOARD = hex2dec('10000077');
CAP_SUPPORTS_NATIVE_SINGLE_PORT = hex2dec('10000078');
CAP_SUPPORT_8_BIT_PACKING = hex2dec('10000079');
CAP_SUPPORT_12_BIT_PACKING = hex2dec('10000080');
HAS_RECORD_HEADERS_SUPPORT = hex2dec('10000081');
CAP_SUPPORT_TRADITIONAL_SAMPLES_INTERLEAVED = hex2dec('10000082');
CAP_SUPPORT_SOFTWARE_CAL = hex2dec('10000083');
%--------------------------------------------------------------------------
% ALAZAR_ECC_MODES
%--------------------------------------------------------------------------
ECC_DISABLE = 0;
ECC_ENABLE = 1;
%--------------------------------------------------------------------------
% ALAZAR_AUX_INPUT_LEVELS
%--------------------------------------------------------------------------
AUX_INPUT_LOW = 0;
AUX_INPUT_HIGH = 1;
%--------------------------------------------------------------------------
% ALAZAR_PACK_MODES
%--------------------------------------------------------------------------
PACK_DEFAULT = 0;
PACK_8_BITS_PER_SAMPLE = 1;
PACK_12_BITS_PER_SAMPLE = 2;
%--------------------------------------------------------------------------
% ALAZAR_API_TRACE_STATES
%--------------------------------------------------------------------------
API_DISABLE_TRACE = 0;
API_ENABLE_TRACE = 1;
%--------------------------------------------------------------------------
% ALAZAR_ADC_MODES
%--------------------------------------------------------------------------
ADC_MODE_DEFAULT = 0;
ADC_MODE_DES = 1;
%--------------------------------------------------------------------------
% ALAZAR_PARAMETERS_UL
%--------------------------------------------------------------------------
SET_ADC_MODE = hex2dec('10000047');
SET_BUFFERS_PER_TRIGGER_ENABLE = hex2dec('10000097');
GET_POWER_MONITOR_STATUS = hex2dec('10000098');
SET_EXT_TRIGGER_RANGE = hex2dec('1000001C');
%--------------------------------------------------------------------------
% ALAZAR_PARAMETERS
%--------------------------------------------------------------------------
DATA_WIDTH                       = hex2dec('10000009');
SETGET_ASYNC_BUFFSIZE_BYTES      = hex2dec('10000039');
SETGET_ASYNC_BUFFCOUNT           = hex2dec('10000040');
GET_ASYNC_BUFFERS_PENDING        = hex2dec('10000050');
GET_ASYNC_BUFFERS_PENDING_FULL   = hex2dec('10000051');
GET_ASYNC_BUFFERS_PENDING_EMPTY  = hex2dec('10000052');
SET_DATA_FORMAT                  = hex2dec('10000041');
GET_DATA_FORMAT                  = hex2dec('10000042');
GET_SAMPLES_PER_TIMESTAMP_CLOCK  = hex2dec('10000044');
GET_RECORDS_CAPTURED             = hex2dec('10000045');
ECC_MODE                         = hex2dec('10000048');
GET_AUX_INPUT_LEVEL              = hex2dec('10000049');
GET_CHANNELS_PER_BOARD           = hex2dec('10000070');
GET_FPGA_TEMPERATURE             = hex2dec('10000080');
PACK_MODE                        = hex2dec('10000072');
SET_SINGLE_CHANNEL_MODE          = hex2dec('10000043');
API_FLAGS                        = hex2dec('10000090');
SET_SOFTWARE_CAL_MECHANISM       = hex2dec('10000100');
%--------------------------------------------------------------------------
% ALAZAR_BOARD_OPTIONS_LOW
%--------------------------------------------------------------------------
OPTION_STREAMING_DMA             = uint32(2^0);
OPTION_EXTERNAL_CLOCK            = uint32(2^1);
OPTION_DUAL_PORT_MEMORY          = uint32(2^2);
OPTION_180MHZ_OSCILLATOR         = uint32(2^3);
OPTION_LVTTL_EXT_CLOCK           = uint32(2^4);
OPTION_SW_SPI                    = uint32(2^5);
OPTION_ALT_INPUT_RANGES          = uint32(2^6);
OPTION_VARIABLE_RATE_10MHZ_PLL   = uint32(2^7);
OPTION_2GHZ_ADC                  = uint32(2^8);
OPTION_DUAL_EDGE_SAMPLING        = uint32(2^9);
%--------------------------------------------------------------------------
% ALAZAR_BOARD_OPTIONS_HIGH
%--------------------------------------------------------------------------
OPTION_USER_CALIBRATION          = uint32(2^7);
OPTION_OEM_FPGA                  = uint32(2^15);
%--------------------------------------------------------------------------
% ALAZAR_SAMPLE_RATES
%--------------------------------------------------------------------------
SAMPLE_RATE_1KSPS           =   hex2dec('00000001');
SAMPLE_RATE_2KSPS           =   hex2dec('00000002');
SAMPLE_RATE_5KSPS           =   hex2dec('00000004');
SAMPLE_RATE_10KSPS          =   hex2dec('00000008');
SAMPLE_RATE_20KSPS          =   hex2dec('0000000A');
SAMPLE_RATE_50KSPS          =   hex2dec('0000000C');
SAMPLE_RATE_100KSPS         =   hex2dec('0000000E');
SAMPLE_RATE_200KSPS         =   hex2dec('00000010');
SAMPLE_RATE_500KSPS         =   hex2dec('00000012');
SAMPLE_RATE_1MSPS           =   hex2dec('00000014');
SAMPLE_RATE_2MSPS           =   hex2dec('00000018');
SAMPLE_RATE_5MSPS           =   hex2dec('0000001A');
SAMPLE_RATE_10MSPS          =   hex2dec('0000001C');
SAMPLE_RATE_20MSPS          =   hex2dec('0000001E');
SAMPLE_RATE_25MSPS          =   hex2dec('00000021');
SAMPLE_RATE_50MSPS          =   hex2dec('00000022');
SAMPLE_RATE_100MSPS         =   hex2dec('00000024');
SAMPLE_RATE_125MSPS         =   hex2dec('00000025');
SAMPLE_RATE_160MSPS         =   hex2dec('00000026');
SAMPLE_RATE_180MSPS         =   hex2dec('00000027');
SAMPLE_RATE_200MSPS         =   hex2dec('00000028');
SAMPLE_RATE_250MSPS         =   hex2dec('0000002B');
SAMPLE_RATE_400MSPS         =   hex2dec('0000002D');
SAMPLE_RATE_500MSPS         =   hex2dec('00000030');
SAMPLE_RATE_800MSPS         =   hex2dec('00000032');
SAMPLE_RATE_1GSPS           =   hex2dec('00000035');
SAMPLE_RATE_1000MSPS        =   hex2dec('00000035');
SAMPLE_RATE_1200MSPS        =   hex2dec('00000037');
SAMPLE_RATE_1500MSPS        =   hex2dec('0000003A');
SAMPLE_RATE_1600MSPS        =   hex2dec('0000003B');
SAMPLE_RATE_1800MSPS        =   hex2dec('0000003D');
SAMPLE_RATE_2000MSPS        =   hex2dec('0000003F');
SAMPLE_RATE_2GSPS           =   hex2dec('0000003F');
SAMPLE_RATE_2400MSPS        =   hex2dec('0000006A');
SAMPLE_RATE_3000MSPS        =   hex2dec('00000075');
SAMPLE_RATE_3GSPS           =   hex2dec('00000075');
SAMPLE_RATE_3600MSPS        =   hex2dec('0000007B');
SAMPLE_RATE_4000MSPS        =   hex2dec('00000080');
SAMPLE_RATE_4GSPS           =   hex2dec('00000080');
SAMPLE_RATE_300MSPS         =   hex2dec('00000090');
SAMPLE_RATE_350MSPS         =   hex2dec('00000094');
SAMPLE_RATE_370MSPS         =   hex2dec('00000096');
SAMPLE_RATE_USER_DEF        =   hex2dec('00000040');
%--------------------------------------------------------------------------
% IMPEDANCES
%--------------------------------------------------------------------------
IMPEDANCE_1M_OHM            =   hex2dec('00000001');
IMPEDANCE_50_OHM            =   hex2dec('00000002');
IMPEDANCE_75_OHM            =   hex2dec('00000004');
IMPEDANCE_300_OHM           =   hex2dec('00000008');
IMPEDANCE_100_OHM           =   hex2dec('00000010');
%--------------------------------------------------------------------------
% ALAZAR_CLOCK_SOURCES
%--------------------------------------------------------------------------
INTERNAL_CLOCK              =   hex2dec('00000001');
EXTERNAL_CLOCK              =   hex2dec('00000002');
FAST_EXTERNAL_CLOCK         =   hex2dec('00000002');
MEDIMUM_EXTERNAL_CLOCK      =   hex2dec('00000003');
MEDIUM_EXTERNAL_CLOCK       =   hex2dec('00000003');
SLOW_EXTERNAL_CLOCK         =   hex2dec('00000004');
EXTERNAL_CLOCK_AC           =   hex2dec('00000005');
EXTERNAL_CLOCK_DC           =   hex2dec('00000006');
EXTERNAL_CLOCK_10MHZ_REF    =   hex2dec('00000007');
INTERNAL_CLOCK_10MHZ_REF    =   hex2dec('00000008');
EXTERNAL_CLOCK_10MHZ_PXI    =   hex2dec('0000000A');
EXTERNAL_CLOCK_10MHz_REF    = EXTERNAL_CLOCK_10MHZ_REF;
%--------------------------------------------------------------------------
% ALAZAR_CLOCK_EDGES
%--------------------------------------------------------------------------
CLOCK_EDGE_RISING           = hex2dec('00000000');
CLOCK_EDGE_FALLING          = hex2dec('00000001');
%--------------------------------------------------------------------------
% ALAZAR_INPUT_RANGES
%--------------------------------------------------------------------------
INPUT_RANGE_PM_20_MV = hex2dec('00000001');
INPUT_RANGE_PM_40_MV = hex2dec('00000002');
INPUT_RANGE_PM_50_MV = hex2dec('00000003');
INPUT_RANGE_PM_80_MV = hex2dec('00000004');
INPUT_RANGE_PM_100_MV = hex2dec('00000005');
INPUT_RANGE_PM_200_MV = hex2dec('00000006');
INPUT_RANGE_PM_400_MV = hex2dec('00000007');
INPUT_RANGE_PM_500_MV = hex2dec('00000008');
INPUT_RANGE_PM_800_MV = hex2dec('00000009');
INPUT_RANGE_PM_1_V = hex2dec('0000000A');
INPUT_RANGE_PM_2_V = hex2dec('0000000B');
INPUT_RANGE_PM_4_V = hex2dec('0000000C');
INPUT_RANGE_PM_5_V = hex2dec('0000000D');
INPUT_RANGE_PM_8_V = hex2dec('0000000E');
INPUT_RANGE_PM_10_V = hex2dec('0000000F');
INPUT_RANGE_PM_20_V = hex2dec('00000010');
INPUT_RANGE_PM_40_V = hex2dec('00000011');
INPUT_RANGE_PM_16_V = hex2dec('00000012');
INPUT_RANGE_HIFI = hex2dec('00000020');
INPUT_RANGE_PM_1_V_25 = hex2dec('00000021');
INPUT_RANGE_PM_2_V_5 = hex2dec('00000025');
INPUT_RANGE_PM_125_MV = hex2dec('00000028');
INPUT_RANGE_PM_250_MV = hex2dec('00000030');
INPUT_RANGE_0_TO_40_MV = hex2dec('00000031');
INPUT_RANGE_0_TO_80_MV = hex2dec('00000032');
INPUT_RANGE_0_TO_100_MV = hex2dec('00000033');
INPUT_RANGE_0_TO_160_MV = hex2dec('00000034');
INPUT_RANGE_0_TO_200_MV = hex2dec('00000035');
INPUT_RANGE_0_TO_250_MV = hex2dec('00000036');
INPUT_RANGE_0_TO_400_MV = hex2dec('00000037');
INPUT_RANGE_0_TO_500_MV = hex2dec('00000038');
INPUT_RANGE_0_TO_800_MV = hex2dec('00000039');
INPUT_RANGE_0_TO_1_V = hex2dec('0000003A');
INPUT_RANGE_0_TO_1600_MV = hex2dec('0000003B');
INPUT_RANGE_0_TO_2_V = hex2dec('0000003C');
INPUT_RANGE_0_TO_2_V_5 = hex2dec('0000003D');
INPUT_RANGE_0_TO_4_V = hex2dec('0000003E');
INPUT_RANGE_0_TO_5_V = hex2dec('0000003F');
INPUT_RANGE_0_TO_8_V = hex2dec('00000040');
INPUT_RANGE_0_TO_10_V = hex2dec('00000041');
INPUT_RANGE_0_TO_16_V = hex2dec('00000042');
INPUT_RANGE_0_TO_20_V = hex2dec('00000043');
INPUT_RANGE_0_TO_80_V = hex2dec('00000044');
INPUT_RANGE_0_TO_32_V = hex2dec('00000045');
INPUT_RANGE_0_TO_MINUS_40_MV = hex2dec('00000046');
INPUT_RANGE_0_TO_MINUS_80_MV = hex2dec('00000047');
INPUT_RANGE_0_TO_MINUS_100_MV = hex2dec('00000048');
INPUT_RANGE_0_TO_MINUS_160_MV = hex2dec('00000049');
INPUT_RANGE_0_TO_MINUS_200_MV = hex2dec('0000004A');
INPUT_RANGE_0_TO_MINUS_250_MV = hex2dec('0000004B');
INPUT_RANGE_0_TO_MINUS_400_MV = hex2dec('0000004C');
INPUT_RANGE_0_TO_MINUS_500_MV = hex2dec('0000004D');
INPUT_RANGE_0_TO_MINUS_800_MV = hex2dec('0000004E');
INPUT_RANGE_0_TO_MINUS_1_V = hex2dec('0000004F');
INPUT_RANGE_0_TO_MINUS_1600_MV = hex2dec('00000050');
INPUT_RANGE_0_TO_MINUS_2_V = hex2dec('00000051');
INPUT_RANGE_0_TO_MINUS_2_V_5 = hex2dec('00000052');
INPUT_RANGE_0_TO_MINUS_4_V = hex2dec('00000053');
INPUT_RANGE_0_TO_MINUS_5_V = hex2dec('00000054');
INPUT_RANGE_0_TO_MINUS_8_V = hex2dec('00000055');
INPUT_RANGE_0_TO_MINUS_10_V = hex2dec('00000056');
INPUT_RANGE_0_TO_MINUS_16_V = hex2dec('00000057');
INPUT_RANGE_0_TO_MINUS_20_V = hex2dec('00000058');
INPUT_RANGE_0_TO_MINUS_80_V = hex2dec('00000059');
INPUT_RANGE_0_TO_MINUS_32_V = hex2dec('00000060');
%--------------------------------------------------------------------------
% ALAZAR_COUPLINGS
%--------------------------------------------------------------------------
AC_COUPLING = 1;
DC_COUPLING = 2;
GND_COUPLING = 4;
%--------------------------------------------------------------------------
% ALAZAR_TRIGGER_ENGINES
%--------------------------------------------------------------------------
TRIG_ENGINE_J = 0;
TRIG_ENGINE_K = 1;
%--------------------------------------------------------------------------
% ALAZAR_TRIGGER_OPERATIONS
%--------------------------------------------------------------------------
TRIG_ENGINE_OP_J = 0;
TRIG_ENGINE_OP_K = 1;
TRIG_ENGINE_OP_J_OR_K = 2;
%--------------------------------------------------------------------------
% ALAZAR_TRIGGER_SOURCES
%--------------------------------------------------------------------------
TRIG_CHAN_A = hex2dec('00000000');
TRIG_CHAN_B = hex2dec('00000001');
TRIG_EXTERNAL = hex2dec('00000002');
TRIG_DISABLE = hex2dec('00000003');
TRIG_CHAN_C = hex2dec('00000004');
TRIG_CHAN_D = hex2dec('00000005');
TRIG_CHAN_E = hex2dec('00000006');
TRIG_CHAN_F = hex2dec('00000007');
TRIG_CHAN_G = hex2dec('00000008');
TRIG_CHAN_H = hex2dec('00000009');
TRIG_CHAN_I = hex2dec('0000000A');
TRIG_CHAN_J = hex2dec('0000000B');
TRIG_CHAN_K = hex2dec('0000000C');
TRIG_CHAN_L = hex2dec('0000000D');
TRIG_CHAN_M = hex2dec('0000000E');
TRIG_CHAN_N = hex2dec('0000000F');
TRIG_CHAN_O = hex2dec('00000010');
TRIG_CHAN_P = hex2dec('00000011');
%--------------------------------------------------------------------------
% ALAZAR_TRIGGER_SLOPES
%--------------------------------------------------------------------------
TRIGGER_SLOPE_POSITIVE = 1;
TRIGGER_SLOPE_NEGATIVE = 2;
%--------------------------------------------------------------------------
% ALAZAR_CHANNELS
%--------------------------------------------------------------------------
CHANNEL_ALL = hex2dec('00000000');
CHANNEL_A = hex2dec('00000001');
CHANNEL_B = hex2dec('00000002');
CHANNEL_C = hex2dec('00000004');
CHANNEL_D = hex2dec('00000008');
CHANNEL_E = hex2dec('00000010');
CHANNEL_F = hex2dec('00000020');
CHANNEL_G = hex2dec('00000040');
CHANNEL_H = hex2dec('00000080');
CHANNEL_I = hex2dec('00000100');
CHANNEL_J = hex2dec('00000200');
CHANNEL_K = hex2dec('00000400');
CHANNEL_L = hex2dec('00000800');
CHANNEL_M = hex2dec('00001000');
CHANNEL_N = hex2dec('00002000');
CHANNEL_O = hex2dec('00004000');
CHANNEL_P = hex2dec('00008000');
%--------------------------------------------------------------------------
% ALAZAR_LED
%--------------------------------------------------------------------------
LED_OFF = 0;
LED_ON = 1;
%--------------------------------------------------------------------------
% ALAZAR_EXTERNAL_TRIGGER_RANGES
%--------------------------------------------------------------------------
ETR_5V = 0;
ETR_1V = 1;
ETR_2V5 = 3;
ETR_5V_50OHM = 0;
ETR_1V_50OHM = 1;
ETR_TTL = 2;
ETR_2V5_50OHM = 3;
ETR_5V_300OHM = 4;
%--------------------------------------------------------------------------
% ALAZAR_POWER_STATES
%--------------------------------------------------------------------------
POWER_OFF = 0;
POWER_ON = 1;
%--------------------------------------------------------------------------
% ALAZAR_SOFTWARE_EVENTS_CONTROL
%--------------------------------------------------------------------------
SW_EVENTS_OFF = 0;
SW_EVENTS_ON = 1;
%--------------------------------------------------------------------------
% ALAZAR_AUX_IO_MODES
%--------------------------------------------------------------------------
AUX_OUT_TRIGGER = 0;
AUX_IN_TRIGGER_ENABLE = 1;
AUX_OUT_PACER = 2;
AUX_OUT_SERIAL_DATA = 14;
AUX_IN_AUXILIARY = 13;
%--------------------------------------------------------------------------
% ALAZAR_STOS_OPTIONS
%--------------------------------------------------------------------------
STOS_OPTION_DEFER_START_CAPTURE = 1;
%--------------------------------------------------------------------------
% ALAZAR_SAMPLE_SKIPPING_MODES
%--------------------------------------------------------------------------
SSM_DISABLE = 0;
SSM_ENABLE = 1;
%--------------------------------------------------------------------------
% ALAZAR_COPROCESSOR_DOWNLOAD_OPTIONS
%--------------------------------------------------------------------------
CPF_OPTION_DMA_DOWNLOAD = 1;
%--------------------------------------------------------------------------
% ALAZAR_LSB
%--------------------------------------------------------------------------
LSB_DEFAULT = 0;
LSB_EXT_TRIG = 1;
LSB_AUX_IN_2 = 2;
LSB_AUX_IN_1 = 3;
%--------------------------------------------------------------------------
% DSP_WINDOW_ITEMS
%--------------------------------------------------------------------------
DSP_WINDOW_NONE = 0;
DSP_WINDOW_HANNING = 1;
DSP_WINDOW_HAMMING = 2;
DSP_WINDOW_BLACKMAN = 3;
DSP_WINDOW_BLACKMAN_HARRIS = 4;
DSP_WINDOW_BARTLETT = 5;
%--------------------------------------------------------------------------
% DSP_MODULE_TYPE
%--------------------------------------------------------------------------
DSP_MODULE_NONE = hex2dec('FFFF');
DSP_MODULE_FFT = hex2dec('10000');
DSP_MODULE_PCD = hex2dec('10001');
DSP_MODULE_SSK = hex2dec('10002');
DSP_MODULE_DIS = hex2dec('10003');
%--------------------------------------------------------------------------
% DSP_PARAMETERS_U32
%--------------------------------------------------------------------------
DSP_RAW_PLUS_FFT_SUPPORTED = 0;
DSP_FFT_SUBTRACTOR_SUPPORTED = 1;
%--------------------------------------------------------------------------
% DSP_PARAMETERS_S32
%--------------------------------------------------------------------------
DSP_FFT_POSTPROC_REAL_A = 0;
DSP_FFT_POSTPROC_IMAG_A = 1;
%--------------------------------------------------------------------------
% DSP_PARAMETERS_FLOAT
%--------------------------------------------------------------------------
DSP_FFT_POSTPROC_REAL_B = 0;
DSP_FFT_POSTPROC_REAL_C = 1;
DSP_FFT_POSTPROC_IMAG_B = 2;
DSP_FFT_POSTPROC_IMAG_C = 3;
DSP_FFT_POSTPROC_SCALE_OUT_MAIN = 4;
DSP_FFT_POSTPROC_SCALE_OUT_SEC = 5;
%--------------------------------------------------------------------------
% FFT_OUTPUT_FORMAT
%--------------------------------------------------------------------------
FFT_OUTPUT_FORMAT_U32_AMP2 = hex2dec('0');
FFT_OUTPUT_FORMAT_U16_LOG = hex2dec('1');
FFT_OUTPUT_FORMAT_U16_AMP2 = hex2dec('101');
FFT_OUTPUT_FORMAT_U8_LOG = hex2dec('2');
FFT_OUTPUT_FORMAT_U8_AMP2 = hex2dec('102');
FFT_OUTPUT_FORMAT_S32_REAL = hex2dec('3');
FFT_OUTPUT_FORMAT_S32_IMAG = hex2dec('4');
FFT_OUTPUT_FORMAT_FLOAT_AMP2 = hex2dec('A');
FFT_OUTPUT_FORMAT_FLOAT_LOG = hex2dec('B');
FFT_OUTPUT_FORMAT_RAW_PLUS_FFT = hex2dec('1000');
FFT_OUTPUT_FORMAT_S32_AMP2 = hex2dec('400');
FFT_OUTPUT_FORMAT_S32_LOG = hex2dec('401');
FFT_OUTPUT_FORMAT_S32_PHASE = hex2dec('402');
FFT_OUTPUT_FORMAT_S16_REAL = hex2dec('403');
FFT_OUTPUT_FORMAT_S16_IMAG = hex2dec('404');
FFT_OUTPUT_FORMAT_S16_LOG = hex2dec('405');
FFT_OUTPUT_FORMAT_S16_AMP2 = hex2dec('406');
FFT_OUTPUT_FORMAT_S16_PHASE = hex2dec('407');
FFT_OUTPUT_FORMAT_S8_REAL = hex2dec('408');
FFT_OUTPUT_FORMAT_S8_IMAG = hex2dec('409');
FFT_OUTPUT_FORMAT_S8_LOG = hex2dec('40A');
FFT_OUTPUT_FORMAT_S8_AMP2 = hex2dec('40B');
FFT_OUTPUT_FORMAT_S8_PHASE = hex2dec('40C');
FFT_OUTPUT_FORMAT_FLOAT_REAL = hex2dec('40D');
FFT_OUTPUT_FORMAT_FLOAT_IMAG = hex2dec('40E');
FFT_OUTPUT_FORMAT_FLOAT_PHASE = hex2dec('40F');
FFT_OUTPUT_FORMAT_S16_AMP2_AND_PHASE = hex2dec('410');
FFT_OUTPUT_FORMAT_S16_LOG_AND_PHASE = hex2dec('411');
FFT_OUTPUT_FORMAT_S16_REAL_AND_IMAG = hex2dec('412');
%--------------------------------------------------------------------------
% FFT_FOOTER
%--------------------------------------------------------------------------
FFT_FOOTER_NONE = 0;
FFT_FOOTER_NPT = 1;
%--------------------------------------------------------------------------
% ALAZAR_ADMA_MODES
%--------------------------------------------------------------------------
ADMA_TRADITIONAL_MODE = hex2dec('00000000');
ADMA_CONTINUOUS_MODE = hex2dec('00000100');
ADMA_NPT = hex2dec('00000200');
ADMA_TRIGGERED_STREAMING = hex2dec('00000400');
%--------------------------------------------------------------------------
% ALAZAR_ADMA_FLAGS
%--------------------------------------------------------------------------
ADMA_EXTERNAL_STARTCAPTURE = hex2dec('00000001');
ADMA_ENABLE_RECORD_HEADERS = hex2dec('00000008');
ADMA_SINGLE_DMA_CHANNEL = hex2dec('00000010');
ADMA_ALLOC_BUFFERS = hex2dec('00000020');
ADMA_FIFO_ONLY_STREAMING = hex2dec('00000800');
ADMA_INTERLEAVE_SAMPLES = hex2dec('00001000');
ADMA_GET_PROCESSED_DATA = hex2dec('00002000');
ADMA_DSP = hex2dec('00004000');
ADMA_ENABLE_RECORD_FOOTERS = hex2dec('00010000');
ADMA_DUAL_BUFFER_MODE = hex2dec('00020000');