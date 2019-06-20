#include "perl_libyaml.h"

#define MY_CXT_KEY "YAML::Safe::_cxt"
typedef struct {
  SV *yaml_str;
} my_cxt_t;

START_MY_CXT

static void
init_MY_CXT(pTHX_ my_cxt_t * cxt)
{
  cxt->yaml_str = NULL;
}

MODULE = YAML::Safe		PACKAGE = YAML::Safe

PROTOTYPES: ENABLE

void
Load (...)
  PROTOTYPE: $;$@
  ALIAS:
        Load      = 1
        LoadFile  = 2
        Dump      = 3
        DumpFile  = 4
        SafeLoad  = 9
        SafeLoadFile = 10
        SafeDump  = 11
        SafeDumpFile = 12
  PREINIT:
	YAML *self;
        SV* yaml_arg;
        int yaml_ix = 0;
        int ret, old_safe;
        int err = 0;
  PPCODE:
        /* check if called as method or function */
        if (items >= 2 &&
            SvOK(ST(1)) &&
            SvROK(ST(0)) &&
            SvOBJECT(SvRV(ST(0))) &&
            sv_derived_from (ST(0), "YAML::Safe")) {
          self = (YAML*)SvPVX(SvRV(ST(0)));
          assert(self);
          old_safe = self->flags & F_SAFEMODE;
          yaml_ix = 1;
          yaml_arg = ST(1);
        }
        else if ((items == 1 && ix < 8) || /* no self needed */
                 (ix >= 3 && ix <= 4)) {   /* and Dump, DumpFile can have more args */
          /* default options */
          self = (YAML*)calloc(1, sizeof(YAML));
          yaml_arg = ST(0);
          old_safe = 0;
        } else {
          err = 1;
        }
        PL_markstack_ptr++;
        /* set or unset safemode */
        switch (ix) {
        case 1: if (err)
                  croak ("Usage: Load([YAML::Safe,] str)");
                self->flags &= ~F_SAFEMODE;
                ret = Load(self, yaml_arg);
                break;
        case 2: if (err)
                  croak ("Usage: LoadFile([YAML::Safe,] filename|io)");
                self->flags &= ~F_SAFEMODE;
                ret = LoadFile(self, yaml_arg);
                break;
        case 3: if (err)
                  croak ("Usage: Dump([YAML::Safe,] ...)");
                self->flags &= ~F_SAFEMODE;
                ret = Dump(self, yaml_ix);
                break;
        case 4: if (err)
                  croak ("Usage: DumpFile([YAML::Safe,] filename|io, ...)");
                self->flags &= ~F_SAFEMODE;
                ret = DumpFile(self, yaml_arg, yaml_ix);
                break;
        case 9: if (err)
                  croak ("Usage: SafeLoad(YAML::Safe, str)");
                self->flags |=  F_SAFEMODE;
                ret = Load(self, yaml_arg);
                break;
        case 10: if (err)
                  croak ("Usage: SafeLoadFile(YAML::Safe, filename|io)");
                self->flags |=  F_SAFEMODE;
                ret = LoadFile(self, yaml_arg);
                break;
        case 11: if (err)
                  croak ("Usage: SafeDump(YAML::Safe, ...)");
                self->flags |=  F_SAFEMODE;
                ret = Dump(self, yaml_ix);
                break;
        case 12: if (err)
                  croak ("Usage: SafeDumpFile(YAML::Safe*, filename|io, ...)");
                self->flags |=  F_SAFEMODE;
                ret = DumpFile(self, yaml_arg, yaml_ix);
                break;
        }
        /* restore old safemode */
        if (old_safe) self->flags |=  F_SAFEMODE;
        else          self->flags &= ~F_SAFEMODE;
        if (!ret)
            XSRETURN_UNDEF;
        else
            return;

SV *
libyaml_version()
    CODE:
    {
        const char *v = yaml_get_version_string();
        RETVAL = newSVpv(v, strlen(v));
    }
    OUTPUT: RETVAL

BOOT:
{
        MY_CXT_INIT;
        init_MY_CXT(aTHX_ &MY_CXT);
}

#ifdef USE_ITHREADS

void CLONE (...)
    PPCODE:
        MY_CXT_CLONE; /* possible declaration */
        init_MY_CXT(aTHX_ &MY_CXT);
	/* skip implicit PUTBACK, returning @_ to caller, more efficient*/
        return;

#endif

void xxxEND(...)
    PREINIT:
        dMY_CXT;
        SV * sv;
    PPCODE:
        sv = MY_CXT.yaml_str;
        MY_CXT.yaml_str = NULL;
        SvREFCNT_dec(sv);
	/* skip implicit PUTBACK, returning @_ to caller, more efficient*/
        return;

void DESTROY (YAML *self)
    CODE:
        yaml_destroy (self);

SV* new (char *klass)
    CODE:
        dMY_CXT;
        SV *pv = NEWSV (0, sizeof (YAML));
        SvPOK_only (pv);
        yaml_init ((YAML*)SvPVX (pv));
        RETVAL = sv_bless (newRV (pv), gv_stashpv (klass, 1));
    OUTPUT: RETVAL

YAML*
unicode (YAML *self, int enable = 1)
    ALIAS:
        unicode         = F_UNICODE
        disableblessed  = F_DISABLEBLESSED
        enablecode      = F_ENABLECODE
        nonstrict       = F_NONSTRICT
        loadcode        = F_LOADCODE
        dumpcode        = F_DUMPCODE
        quotenum        = F_QUOTENUM
        noindentmap     = F_NOINDENTMAP
        canonical       = F_CANONICAL
        openended       = F_OPENENDED
    CODE:
        (void)RETVAL;
        if (enable)
          self->flags |=  ix;
        else
          self->flags &= ~ix;
    OUTPUT: self

SV*
get_unicode (YAML *self)
    ALIAS:
        get_unicode         = F_UNICODE
        get_disableblessed  = F_DISABLEBLESSED
        get_enablecode      = F_ENABLECODE
        get_nonstrict       = F_NONSTRICT
        get_loadcode        = F_LOADCODE
        get_dumpcode        = F_DUMPCODE
        get_quotenum        = F_QUOTENUM
        get_noindentmap     = F_NOINDENTMAP
        get_canonical       = F_CANONICAL
        get_openended       = F_OPENENDED
        get_safemode        = F_SAFEMODE
    CODE:
        RETVAL = boolSV (self->flags & ix);
    OUTPUT: RETVAL

SV*
get_boolean (YAML *self)
    CODE:
        if (self->boolean == YAML_BOOLEAN_JSONPP)
          RETVAL = newSVpvn("JSON::PP", sizeof("JSON::PP")-1);
        else if (self->boolean == YAML_BOOLEAN_BOOLEAN)
          RETVAL = newSVpvn("boolean", sizeof("boolean")-1);
        else if (self->boolean == YAML_BOOLEAN_TYPES_SERIALISER)
          RETVAL = newSVpvn("Types::Serialiser", sizeof("Types::Serialiser")-1);
        else
          RETVAL = &PL_sv_undef;
    OUTPUT: RETVAL

YAML*
boolean (YAML *self, SV *value)
    CODE:
        (void)RETVAL;
        if (SvPOK(value)) {
          if (strEQc(SvPVX(value), "JSON::PP")) {
            self->boolean = YAML_BOOLEAN_JSONPP;
          }
          else if (strEQc(SvPVX(value), "boolean")) {
            self->boolean = YAML_BOOLEAN_BOOLEAN;
          }
          else if (strEQc(SvPVX(value), "Types::Serialiser")) {
            self->boolean = YAML_BOOLEAN_TYPES_SERIALISER;
          }
          else if (strEQc(SvPVX(value), "false") || !SvTRUE(value)) {
            self->boolean = YAML_BOOLEAN_NONE;
          }
          else {
            croak("Invalid YAML::Safe->boolean value %s", SvPVX(value));
          }
        } else if (!SvTRUE(value)) {
          self->boolean = YAML_BOOLEAN_NONE;
        } else {
          croak("Invalid YAML::Safe->boolean value");
        }
    OUTPUT: self

char*
get_encoding (YAML *self)
    CODE:
        switch (self->encoding) {
        case YAML_ANY_ENCODING:     RETVAL = "any"; break;
        case YAML_UTF8_ENCODING:    RETVAL = "utf8"; break;
        case YAML_UTF16LE_ENCODING: RETVAL = "utf16le"; break;
        case YAML_UTF16BE_ENCODING: RETVAL = "utf16be"; break;
        default: RETVAL = "utf8"; break;
        }
    OUTPUT: RETVAL

# for parser and emitter
YAML*
encoding (YAML *self, char *value)
    CODE:
        (void)RETVAL;
        if (strEQc(value, "any")) {
          self->encoding = YAML_ANY_ENCODING;
        }
        else if (strEQc(value, "utf8")) {
          self->encoding = YAML_UTF8_ENCODING;
        }
        else if (strEQc(value, "utf16le")) {
          self->encoding = YAML_UTF16LE_ENCODING;
        }
        else if (strEQc(value, "utf16be")) {
          self->encoding = YAML_UTF16BE_ENCODING;
        }
        else {
          croak("Invalid YAML::Safe->encoding value %s", value);
        }
    OUTPUT: self

char*
get_linebreak (YAML *self)
    CODE:
        if (!self->emitter) {
          XSRETURN_UNDEF;
        }
        switch (self->emitter->line_break) {
        case YAML_ANY_BREAK:   RETVAL = "any"; break;
        case YAML_CR_BREAK:    RETVAL = "cr"; break;
        case YAML_LN_BREAK:    RETVAL = "ln"; break;
        case YAML_CRLN_BREAK:  RETVAL = "crln"; break;
        default:               RETVAL = "any"; break;
        }
    OUTPUT: RETVAL

YAML*
linebreak (YAML *self, char *value)
    CODE:
        (void)RETVAL;
        if (!self->emitter) {
          /*fprintf(stderr, "new emitter\n");*/
          Newx(self->emitter,1,yaml_emitter_t);
          yaml_emitter_initialize(self->emitter);
          set_emitter_options(self, self->emitter);
        }
        if (strEQc(value, "any")) {
          yaml_emitter_set_break(self->emitter, YAML_ANY_BREAK);
        }
        else if (strEQc(value, "cr")) {
          yaml_emitter_set_break(self->emitter, YAML_CR_BREAK);
        }
        else if (strEQc(value, "ln")) {
          yaml_emitter_set_break(self->emitter, YAML_LN_BREAK);
        }
        else if (strEQc(value, "crln")) {
          yaml_emitter_set_break(self->emitter, YAML_CRLN_BREAK);
        }
        else {
          croak("Invalid YAML::Safe->linebreak value %s", value);
        }
    OUTPUT: self

UV
get_indent (YAML *self)
    ALIAS:
        get_indent          = 1
        get_wrapwidth       = 2
    CODE:
        # both are for the dumper only
        RETVAL = ix == 1 ? (self->emitter ?
                            self->emitter->best_indent : 2)
               : ix == 2 ? (self->emitter ?
                            self->emitter->best_width : 80)
               : 0;
    OUTPUT: RETVAL

YAML*
indent (YAML *self, IV iv)
    ALIAS:
        indent          = 1
        wrapwidth       = 2
    CODE:
        (void)RETVAL;
        if (!self->emitter) {
          Newx(self->emitter,1,yaml_emitter_t);
          yaml_emitter_initialize(self->emitter);
          set_emitter_options(self, self->emitter);
        }
        if (!SvIOK(ST(1)))
          croak("Invalid argument type");
        if (ix == 1) {
          if (iv < 1 || iv >= 10)
            croak("Invalid YAML::Safe->indent value %"  IVdf, iv);
          yaml_emitter_set_indent(self->emitter, iv);
        }
        else if (ix == 2) {
          if (iv < 1 || iv >= 0xffff)
            croak("Invalid YAML::Safe->wrapwidth value %"  IVdf, iv);
          yaml_emitter_set_width(self->emitter, iv);
        }
    OUTPUT: self

YAML*
SafeClass (YAML *self, ...)
    PROTOTYPE: $;@
    PREINIT:
        int i;
    CODE:
        (void)RETVAL;
        self->flags |= F_SAFEMODE;
        if (!self->safeclasses)
          self->safeclasses = newHV();
        for (i=1; i<items; i++) {
          const char *s = SvPVX_const(ST(i));
          (void)hv_store(self->safeclasses, s, strlen(s), newSViv(1), 0);
        }
    OUTPUT: self
