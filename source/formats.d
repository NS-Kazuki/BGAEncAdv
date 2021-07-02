module formats;

enum AVFormat : string{
  AV_FORMAT_3G2 = "3g2",                          // 3GP2(3GPP2fileformat)
  AV_FORMAT_3GP = "3gp",                          // 3GP(3GPPfileformat)
  AV_FORMAT_4XM = "4xm",                          // 4XTechnologies
  AV_FORMAT_A64 = "a64",                          // a64-videoforCommodore64
  AV_FORMAT_AAC = "aac",                          // rawADTSAAC(AdvancedAudioCoding)
  AV_FORMAT_AC3 = "ac3",                          // rawAC-3
  AV_FORMAT_ADTS = "adts",                        // ADTSAAC(AdvancedAudioCoding)
  AV_FORMAT_ADX = "adx",                          // CRIADX
  AV_FORMAT_AEA = "aea",                          // MDSTUDIOaudio
  AV_FORMAT_AIFF = "aiff",                        // AudioIFF
  AV_FORMAT_ALAW = "alaw",                        // PCMA-law
  AV_FORMAT_AMR = "amr",                          // 3GPPAMR
  AV_FORMAT_ANM = "anm",                          // DeluxePaintAnimation
  AV_FORMAT_APC = "apc",                          // CRYOAPC
  AV_FORMAT_APE = "ape",                          // Monkey'sAudio
  AV_FORMAT_ASF = "asf",                          // ASF(Advanced/ActiveStreamingFormat)
  AV_FORMAT_ASF_STREAM = "asf_stream",            // ASF(Advanced/ActiveStreamingFormat)
  AV_FORMAT_ASS = "ass",                          // SSA(SubStationAlpha)subtitle
  AV_FORMAT_AU = "au",                            // SunAU
  AV_FORMAT_AVI = "avi",                          // AVI(AudioVideoInterleaved)
  AV_FORMAT_AVISYNTH = "avisynth",                // AVISynth
  AV_FORMAT_AVM2 = "avm2",                        // SWF(ShockWaveFlash)(AVM2)
  AV_FORMAT_AVS = "avs",                          // AVS
  AV_FORMAT_BETHSOFTVID = "bethsoftvid",          // BethesdaSoftworksVID
  AV_FORMAT_BFI = "bfi",                          // BruteForce&Ignorance
  AV_FORMAT_BINK = "bink",                        // Bink
  AV_FORMAT_BMV = "bmv",                          // DiscworldIIBMV
  AV_FORMAT_C93 = "c93",                          // InterplayC93
  AV_FORMAT_CAF = "caf",                          // AppleCAF(CoreAudioFormat)
  AV_FORMAT_CAVSVIDEO = "cavsvideo",              // rawChineseAVS(AudioVideoStandard)video
  AV_FORMAT_CDG = "cdg",                          // CDGraphics
  AV_FORMAT_CDXL = "cdxl",                        // CommodoreCDXLvideo
  AV_FORMAT_CRC = "crc",                          // CRCtesting
  AV_FORMAT_DAUD = "daud",                        // D-Cinemaaudio
  AV_FORMAT_DFA = "dfa",                          // ChronomasterDFA
  AV_FORMAT_DIRAC = "dirac",                      // rawDirac
  AV_FORMAT_DNXHD = "dnxhd",                      // rawDNxHD(SMPTEVC-3)
  AV_FORMAT_DSICIN = "dsicin",                    // DelphineSoftwareInternationalCIN
  AV_FORMAT_DTS = "dts",                          // rawDTS
  AV_FORMAT_DV = "dv",                            // DV(DigitalVideo)
  AV_FORMAT_DVD = "dvd",                          // MPEG-2PS(DVDVOB)
  AV_FORMAT_DXA = "dxa",                          // DXA
  AV_FORMAT_EA = "ea",                            // ElectronicArtsMultimedia
  AV_FORMAT_EA_CDATA = "ea_cdata",                // ElectronicArtscdata
  AV_FORMAT_EAC3 = "eac3",                        // rawE-AC-3
  AV_FORMAT_F32BE = "f32be",                      // PCM32-bitfloating-pointbig-endian
  AV_FORMAT_F32LE = "f32le",                      // PCM32-bitfloating-pointlittle-endian
  AV_FORMAT_F64BE = "f64be",                      // PCM64-bitfloating-pointbig-endian
  AV_FORMAT_F64LE = "f64le",                      // PCM64-bitfloating-pointlittle-endian
  AV_FORMAT_FFM = "ffm",                          // FFM(AVserverlivefeed)
  AV_FORMAT_FFMETADATA = "ffmetadata",            // FFmpegmetadataintext
  AV_FORMAT_FILM_CPK = "film_cpk",                // SegaFILM/CPK
  AV_FORMAT_FILMSTRIP = "filmstrip",              // AdobeFilmstrip
  AV_FORMAT_FLAC = "flac",                        // rawFLAC
  AV_FORMAT_FLIC = "flic",                        // FLI/FLC/FLXanimation
  AV_FORMAT_FLV = "flv",                          // FLV(FlashVideo)
  AV_FORMAT_FRAMECRC = "framecrc",                // framecrctesting
  AV_FORMAT_FRAMEMD5 = "framemd5",                // Per-frameMD5testing
  AV_FORMAT_G722 = "g722",                        // rawG.722
  AV_FORMAT_G723_1 = "g723_1",                    // G.723.1
  AV_FORMAT_GIF = "gif",                          // GIFAnimation
  AV_FORMAT_GSM = "gsm",                          // rawGSM
  AV_FORMAT_GXF = "gxf",                          // GXF(GeneraleXchangeFormat)
  AV_FORMAT_H261 = "h261",                        // rawH.261
  AV_FORMAT_H263 = "h263",                        // rawH.263
  AV_FORMAT_H264 = "h264",                        // rawH.264video
  AV_FORMAT_HLS = "hls",                          // AppleHTTPLiveStreaming
  AV_FORMAT_APPLEHTTP = "applehttp",              // AppleHTTPLiveStreaming
  AV_FORMAT_IDCIN = "idcin",                      // idCinematic
  AV_FORMAT_IFF = "iff",                          // IFF(InterchangeFileFormat)
  AV_FORMAT_ILBC = "ilbc",                        // iLBCstorage
  AV_FORMAT_IMAGE2 = "image2",                    // image2sequence
  AV_FORMAT_IMAGE2PIPE = "image2pipe",            // pipedimage2sequence
  AV_FORMAT_INGENIENT = "ingenient",              // rawIngenientMJPEG
  AV_FORMAT_IPMOVIE = "ipmovie",                  // InterplayMVE
  AV_FORMAT_IPOD = "ipod",                        // iPodH.264MP4(MPEG-4Part14)
  AV_FORMAT_ISMV = "ismv",                        // ISMV/ISMA(SmoothStreaming)
  AV_FORMAT_ISS = "iss",                          // FuncomISS
  AV_FORMAT_IV8 = "iv8",                          // IndigoVision8000video
  AV_FORMAT_IVF = "ivf",                          // On2IVF
  AV_FORMAT_JV = "jv",                            // BitmapBrothersJV
  AV_FORMAT_LATM = "latm",                        // LOAS/LATM
  AV_FORMAT_LMLM4 = "lmlm4",                      // rawlmlm4
  AV_FORMAT_LXF = "lxf",                          // VRnativestream(LXF)
  AV_FORMAT_M4V = "m4v",                          // rawMPEG-4video
  AV_FORMAT_MATROSKA = "matroska",                // Matroska
  AV_FORMAT_MD5 = "md5",                          // MD5testing
  AV_FORMAT_MJPEG = "mjpeg",                      // rawMJPEGvideo
  AV_FORMAT_MLP = "mlp",                          // rawMLP
  AV_FORMAT_MM = "mm",                            // AmericanLaserGamesMM
  AV_FORMAT_MMF = "mmf",                          // YamahaSMAF
  AV_FORMAT_MOV = "mov",                          // QuickTime/MOV
  AV_FORMAT_M4A = "m4a",                          // QuickTime/MOV
  AV_FORMAT_MJ2 = "mj2",                          // QuickTime/MOV
  AV_FORMAT_MP2 = "mp2",                          // MP2(MPEGaudiolayer2)
  AV_FORMAT_MP3 = "mp3",                          // MP3(MPEGaudiolayer3)
  AV_FORMAT_MP4 = "mp4",                          // MP4(MPEG-4Part14)
  AV_FORMAT_MPC = "mpc",                          // Musepack
  AV_FORMAT_MPC8 = "mpc8",                        // MusepackSV8
  AV_FORMAT_MPEG = "mpeg",                        // MPEG-1Systems/MPEGprogramstream
  AV_FORMAT_MPEG1VIDEO = "mpeg1video",            // rawMPEG-1video
  AV_FORMAT_MPEG2VIDEO = "mpeg2video",            // rawMPEG-2video
  AV_FORMAT_MPEGTS = "mpegts",                    // MPEG-TS(MPEG-2TransportStream)
  AV_FORMAT_MPEGTSRAW = "mpegtsraw",              // rawMPEG-TS(MPEG-2TransportStream)
  AV_FORMAT_MPEGVIDEO = "mpegvideo",              // rawMPEGvideo
  AV_FORMAT_MPJPEG = "mpjpeg",                    // MIMEmultipartJPEG
  AV_FORMAT_MSNWCTCP = "msnwctcp",                // MSNTCPWebcamstream
  AV_FORMAT_MTV = "mtv",                          // MTV
  AV_FORMAT_MULAW = "mulaw",                      // PCMmu-law
  AV_FORMAT_MVI = "mvi",                          // MotionPixelsMVI
  AV_FORMAT_MXF = "mxf",                          // MXF(MaterialeXchangeFormat)
  AV_FORMAT_MXF_D10 = "mxf_d10",                  // MXF(MaterialeXchangeFormat)D-10Mapping
  AV_FORMAT_MXG = "mxg",                          // MxPEGclip
  AV_FORMAT_NC = "nc",                            // NCcamerafeed
  AV_FORMAT_NSV = "nsv",                          // NullsoftStreamingVideo
  AV_FORMAT_NULL = "null",                        // rawnullvideo
  AV_FORMAT_NUT = "nut",                          // NUT
  AV_FORMAT_NUV = "nuv",                          // NuppelVideo
  AV_FORMAT_OGG = "ogg",                          // Ogg
  AV_FORMAT_OMA = "oma",                          // SonyOpenMGaudio
  AV_FORMAT_PMP = "pmp",                          // PlaystationPortablePMP
  AV_FORMAT_PSP = "psp",                          // PSPMP4(MPEG-4Part14)
  AV_FORMAT_PSXSTR = "psxstr",                    // SonyPlaystationSTR
  AV_FORMAT_PVA = "pva",                          // TechnoTrendPVA
  AV_FORMAT_QCP = "qcp",                          // QCP
  AV_FORMAT_R3D = "r3d",                          // REDCODER3D
  AV_FORMAT_RAWVIDEO = "rawvideo",                // rawvideo
  AV_FORMAT_RCV = "rcv",                          // VC-1testbitstream
  AV_FORMAT_RL2 = "rl2",                          // RL2
  AV_FORMAT_RM = "rm",                            // RealMedia
  AV_FORMAT_ROQ = "roq",                          // rawidRoQ
  AV_FORMAT_RPL = "rpl",                          // RPL/ARMovie
  AV_FORMAT_RSO = "rso",                          // LegoMindstormsRSO
  AV_FORMAT_RTP = "rtp",                          // RTPoutput
  AV_FORMAT_RTSP = "rtsp",                        // RTSPoutput
  AV_FORMAT_S16BE = "s16be",                      // PCMsigned16-bitbig-endian
  AV_FORMAT_S16LE = "s16le",                      // PCMsigned16-bitlittle-endian
  AV_FORMAT_S24BE = "s24be",                      // PCMsigned24-bitbig-endian
  AV_FORMAT_S24LE = "s24le",                      // PCMsigned24-bitlittle-endian
  AV_FORMAT_S32BE = "s32be",                      // PCMsigned32-bitbig-endian
  AV_FORMAT_S32LE = "s32le",                      // PCMsigned32-bitlittle-endian
  AV_FORMAT_S8 = "s8",                            // PCMsigned8-bit
  AV_FORMAT_SAP = "sap",                          // SAPoutput
  AV_FORMAT_SDP = "sdp",                          // SDP
  AV_FORMAT_SEGMENT = "segment",                  // segment
  AV_FORMAT_SHN = "shn",                          // rawShorten
  AV_FORMAT_SIFF = "siff",                        // BeamSoftwareSIFF
  AV_FORMAT_SMJPEG = "smjpeg",                    // LokiSDLMJPEG
  AV_FORMAT_SMK = "smk",                          // Smackervideo
  AV_FORMAT_SMOOTHSTREAMING = "smoothstreaming",  // SmoothStreamingMuxer
  AV_FORMAT_SOL = "sol",                          // SierraSOL
  AV_FORMAT_SOX = "sox",                          // SoXnative
  AV_FORMAT_SPDIF = "spdif",                      // IEC61937(usedonS/PDIF-IEC958)
  AV_FORMAT_SRT = "srt",                          // SubRipsubtitle
  AV_FORMAT_SVCD = "svcd",                        // MPEG-2PS(SVCD)
  AV_FORMAT_SWF = "swf",                          // SWF(ShockWaveFlash)
  AV_FORMAT_TAK = "tak",                          // rawTAK
  AV_FORMAT_THP = "thp",                          // THP
  AV_FORMAT_TIERTEXSEQ = "tiertexseq",            // TiertexLimitedSEQ
  AV_FORMAT_TMV = "tmv",                          // 8088flexTMV
  AV_FORMAT_TRUEHD = "truehd",                    // rawTrueHD
  AV_FORMAT_TTA = "tta",                          // TTA(TrueAudio)
  AV_FORMAT_TTY = "tty",                          // Tele-typewriter
  AV_FORMAT_TXD = "txd",                          // RenderwareTeXtureDictionary
  AV_FORMAT_U16BE = "u16be",                      // PCMunsigned16-bitbig-endian
  AV_FORMAT_U16LE = "u16le",                      // PCMunsigned16-bitlittle-endian
  AV_FORMAT_U24BE = "u24be",                      // PCMunsigned24-bitbig-endian
  AV_FORMAT_U24LE = "u24le",                      // PCMunsigned24-bitlittle-endian
  AV_FORMAT_U32BE = "u32be",                      // PCMunsigned32-bitbig-endian
  AV_FORMAT_U32LE = "u32le",                      // PCMunsigned32-bitlittle-endian
  AV_FORMAT_U8 = "u8",                            // PCMunsigned8-bit
  AV_FORMAT_VC1 = "vc1",                          // rawVC-1
  AV_FORMAT_VC1TEST = "vc1test",                  // VC-1testbitstream
  AV_FORMAT_VCD = "vcd",                          // MPEG-1Systems/MPEGprogramstream(VCD)
  AV_FORMAT_VFWCAP = "vfwcap",                    // VfWvideocapture
  AV_FORMAT_VMD = "vmd",                          // SierraVMD
  AV_FORMAT_VOB = "vob",                          // MPEG-2PS(VOB)
  AV_FORMAT_VOC = "voc",                          // CreativeVoice
  AV_FORMAT_VQF = "vqf",                          // NipponTelegraphandTelephoneCorporation(NTT)TwinVQ
  AV_FORMAT_W64 = "w64",                          // SonyWave64
  AV_FORMAT_WAV = "wav",                          // WAV/WAVE(WaveformAudio)
  AV_FORMAT_WC3MOVIE = "wc3movie",                // WingCommanderIIImovie
  AV_FORMAT_WEBM = "webm",                        // WebM
  AV_FORMAT_WSAUD = "wsaud",                      // WestwoodStudiosaudio
  AV_FORMAT_WSVQA = "wsvqa",                      // WestwoodStudiosVQA
  AV_FORMAT_WTV = "wtv",                          // WindowsTelevision(WTV)
  AV_FORMAT_WV = "wv",                            // rawWavPack
  AV_FORMAT_XA = "xa",                            // MaxisXA
  AV_FORMAT_XMV = "xmv",                          // MicrosoftXMV
  AV_FORMAT_XWMA = "xwma",                        // MicrosoftxWMA
  AV_FORMAT_YOP = "yop",                          // PsygnosisYOP
  AV_FORMAT_YUV4MPEGPIPE = "yuv4mpegpipe",        // YUV4MPEGpipe
}

char* ptr(AVFormat type){
  return cast(char*)(type.ptr);
}