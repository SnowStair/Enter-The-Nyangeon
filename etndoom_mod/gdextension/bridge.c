/* ETNDOOM M0: Godot's C ABI only. Core globals live in a fresh DLL per session. */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>
#include "gdextension_interface.h"

#ifndef M0_BRIDGE_BUILD
#define M0_BRIDGE_BUILD "development"
#endif

typedef struct { uint64_t data[2]; } Builtin;
static GDExtensionClassLibraryPtr library;
static Builtin class_name, parent_name, empty_name, empty_string;
static GDExtensionInterfaceStringNameNewWithUtf8Chars sn_new;
static GDExtensionInterfaceStringNewWithUtf8Chars str_new;
static GDExtensionInterfaceStringToUtf8Chars str_utf8;
static GDExtensionInterfaceGetVariantFromTypeConstructor from_type;
static GDExtensionInterfaceGetVariantToTypeConstructor to_type;
static GDExtensionInterfaceVariantGetPtrDestructor destructor;
static GDExtensionInterfaceVariantGetPtrConstructor constructor;
static GDExtensionInterfaceVariantGetPtrBuiltinMethod builtin_method;
static GDExtensionInterfacePackedByteArrayOperatorIndex byte_index;
static GDExtensionInterfaceClassdbConstructObject construct_object;
static GDExtensionInterfaceObjectSetInstance set_instance;
static GDExtensionInterfaceClassdbRegisterExtensionClass2 register_class;
static GDExtensionInterfaceClassdbRegisterExtensionClassMethod register_method;
static GDExtensionInterfaceClassdbUnregisterExtensionClass unregister_class;
static GDExtensionInterfaceVariantGetType variant_type;
static GDExtensionPtrBuiltInMethod bytes_resize;
static DWORD main_thread;

typedef struct {
    HMODULE core;
    const char *(*build_info)(void);
    int (*create)(const char*,const char*,const char*,int,int,int);
    int (*step)(int,int,int,int,int);
    const char *(*snapshot)(void);
    const char *(*map)(void);
    int (*frame)(uint8_t*,int);
    int (*width)(void), (*height)(void);
    const char *(*error)(void);
    void (*destroy)(void);
    uint64_t (*allocated_bytes)(void), (*allocation_count)(void);
} Bridge;
static Bridge *active;

static char *get_string(GDExtensionConstVariantPtr arg) {
    Builtin s = {0};
    to_type(GDEXTENSION_VARIANT_TYPE_STRING)(&s, (void*)arg);
    int64_t n = str_utf8(&s, NULL, 0);
    char *out = calloc((size_t)n + 1, 1);
    str_utf8(&s, out, n);
    destructor(GDEXTENSION_VARIANT_TYPE_STRING)(&s);
    return out;
}
static int64_t get_int(GDExtensionConstVariantPtr arg) {
    int64_t n = 0; to_type(GDEXTENSION_VARIANT_TYPE_INT)(&n, (void*)arg); return n;
}
static void return_string(GDExtensionVariantPtr out, const char *text) {
    Builtin s = {0}; str_new(&s, text ? text : "{}");
    from_type(GDEXTENSION_VARIANT_TYPE_STRING)(out, &s);
    destructor(GDEXTENSION_VARIANT_TYPE_STRING)(&s);
}
static void return_error(GDExtensionVariantPtr out, const char *stage, const char *message) {
    char escaped[4096], result[4400]; size_t n=0;
    for (const unsigned char *p=(const unsigned char*)message; *p && n<sizeof(escaped)-8; p++) {
        if (*p=='"' || *p=='\\') escaped[n++]='\\';
        if (*p < 32) { escaped[n++]=' '; continue; }
        escaped[n++]=(char)*p;
    }
    escaped[n]=0;
    snprintf(result,sizeof(result),"{\"ok\":false,\"stage\":\"%s\",\"error\":\"%s\"}",stage,escaped);
    return_string(out,result);
}
static void close_core_report(Bridge *b,char *report,size_t capacity) {
    uint64_t before_bytes=0,before_count=0,after_bytes=0,after_count=0;
    int unloaded=1,had_core=b->core!=NULL;
    if (b->core) {
        if(b->allocated_bytes)before_bytes=b->allocated_bytes();
        if(b->allocation_count)before_count=b->allocation_count();
        if(b->destroy) b->destroy();
        if(b->allocated_bytes)after_bytes=b->allocated_bytes();
        if(b->allocation_count)after_count=b->allocation_count();
        unloaded=FreeLibrary(b->core)!=0;
    }
    if(active==b) active=NULL;
    memset(b,0,sizeof(*b));
    if(report)snprintf(report,capacity,"{\"ok\":%s,\"had_core\":%s,\"unloaded\":%s,\"before_bytes\":%llu,\"before_count\":%llu,\"after_bytes\":%llu,\"after_count\":%llu}",unloaded?"true":"false",had_core?"true":"false",unloaded?"true":"false",(unsigned long long)before_bytes,(unsigned long long)before_count,(unsigned long long)after_bytes,(unsigned long long)after_count);
}
static void close_core(Bridge *b) {close_core_report(b,NULL,0);}
static GDExtensionObjectPtr create_instance(void *unused) {
    (void)unused; Bridge *b=calloc(1,sizeof(Bridge));
    GDExtensionObjectPtr obj=construct_object(&parent_name);
    set_instance(obj,&class_name,b); return obj;
}
static void free_instance(void *unused, GDExtensionClassInstancePtr instance) {
    (void)unused; close_core(instance); free(instance);
}
enum { OPEN, STEP, SNAPSHOT, MAP, BUILD_INFO, FRAMEBUFFER, CLOSE, DIMENSIONS };
static const int counts[]={7,5,0,0,0,0,0,0};
static void dispatch(void *method, GDExtensionClassInstancePtr instance,
 const GDExtensionConstVariantPtr *args, GDExtensionInt argc,
 GDExtensionVariantPtr out, GDExtensionCallError *err) {
    int id=(int)(intptr_t)method; Bridge *b=instance;
    err->error=GDEXTENSION_CALL_OK;
    if(argc!=counts[id]) { err->error=GDEXTENSION_CALL_ERROR_TOO_FEW_ARGUMENTS; err->expected=counts[id]; return_string(out,"{}"); return; }
    for(int i=0;i<argc;i++) {
        GDExtensionVariantType expected=(id==OPEN && i<4)?GDEXTENSION_VARIANT_TYPE_STRING:GDEXTENSION_VARIANT_TYPE_INT;
        if(variant_type(args[i])!=expected) {err->error=GDEXTENSION_CALL_ERROR_INVALID_ARGUMENT;err->argument=i;err->expected=expected;return_string(out,"{}");return;}
        if(expected==GDEXTENSION_VARIANT_TYPE_INT && (get_int(args[i])<INT_MIN || get_int(args[i])>INT_MAX)) {return_error(out,"argument","整数超出 int32 范围");return;}
    }
    if(GetCurrentThreadId()!=main_thread) {return_error(out,"thread","仅支持宿主主线程串行调用");return;}
    if(id==CLOSE) {char report[512];close_core_report(b,report,sizeof(report));return_string(out,report);return;}
    if(id==OPEN) {
        if(active || b->core) {return_error(out,"create","已有活动会话");return;}
        char *v[4]; for(int i=0;i<4;i++) v[i]=get_string(args[i]);
        wchar_t path[32768];
        if(!MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,v[0],-1,path,32768)) {return_error(out,"core_path","UTF-8 路径无效或过长");goto release_args;}
        /* LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR requires Win32 separators for dependency lookup. */
        for(wchar_t *p=path;*p;p++)if(*p==L'/')*p=L'\\';
        b->core=LoadLibraryExW(path,NULL,LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR|LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);
        if(!b->core) {char msg[128];snprintf(msg,sizeof(msg),"LoadLibraryExW failed: Win32=%lu (core/dependency/architecture)",GetLastError());return_error(out,"load_core",msg);goto release_args;}
#define RESOLVE(field,symbol) b->field=(void*)GetProcAddress(b->core,symbol); if(!b->field) {return_error(out,"core_abi","缺少必需导出 " symbol);close_core(b);goto release_args;}
        RESOLVE(build_info,"m0_build_info"); RESOLVE(create,"m0_create"); RESOLVE(step,"m0_step");
        RESOLVE(snapshot,"m0_snapshot"); RESOLVE(map,"m0_map"); RESOLVE(frame,"m0_frame");
        RESOLVE(width,"m0_width"); RESOLVE(height,"m0_height"); RESOLVE(error,"m0_error"); RESOLVE(destroy,"m0_destroy");
        RESOLVE(allocated_bytes,"m0_allocated_bytes"); RESOLVE(allocation_count,"m0_allocation_count");
#undef RESOLVE
        const char *abi=strstr(b->build_info(),"\"abi\"");
        if(!abi || !(abi=strchr(abi,':')) || strtol(abi+1,NULL,10)!=1) {return_error(out,"core_abi","核心 ABI 不匹配，预期 1");close_core(b);goto release_args;}
        if(b->create(v[1],v[2],v[3],(int)get_int(args[4]),(int)get_int(args[5]),(int)get_int(args[6]))!=0) {
            return_error(out,"create",b->error());close_core(b);goto release_args;
        }
        active=b; return_string(out,"{\"ok\":true}");
release_args:
        for(int i=0;i<4;i++) free(v[i]);
        return;
    }
    if(id==BUILD_INFO && !b->core) {return_string(out,"{\"bridge_abi\":1,\"bridge_build\":\"" M0_BRIDGE_BUILD "\",\"core_loaded\":false}");return;}
    if(!b->core) {return_error(out,"state","无活动会话");return;}
    if(id==STEP) {
        if(b->step((int)get_int(args[0]),(int)get_int(args[1]),(int)get_int(args[2]),(int)get_int(args[3]),(int)get_int(args[4]))!=0) return_error(out,"step",b->error());
        else return_string(out,b->snapshot());
        return;
    }
    if(id==SNAPSHOT) return_string(out,b->snapshot());
    if(id==MAP) return_string(out,b->map());
    if(id==BUILD_INFO) {
        const char *core=b->build_info();char text[8192];
        snprintf(text,sizeof(text),"{\"bridge_abi\":1,\"bridge_build\":\"" M0_BRIDGE_BUILD "\",%s",core&&core[0]=='{'?core+1:"\"core_info_invalid\":true}");
        return_string(out,text);
    }
    if(id==DIMENSIONS) {char text[80];snprintf(text,sizeof(text),"{\"width\":%d,\"height\":%d}",b->width(),b->height());return_string(out,text);}
    if(id==FRAMEBUFFER) {
        Builtin bytes={0}; constructor(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY,0)(&bytes,NULL);
        int64_t size=(int64_t)b->width()*b->height()*4, status=0;
        if(size>0 && size<=4096*4096*4) {
            const void *p[]={&size}; bytes_resize(&bytes,p,&status,1);
            if(!status && b->frame(byte_index(&bytes,0),(int)size)<0) {int64_t zero=0;const void *empty[]={&zero};bytes_resize(&bytes,empty,&status,1);}
        }
        from_type(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY)(out,&bytes);
        destructor(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY)(&bytes);
    }
}
static void initialize(void *unused,GDExtensionInitializationLevel level) {
    (void)unused; if(level!=GDEXTENSION_INITIALIZATION_SCENE)return;
    main_thread=GetCurrentThreadId(); sn_new(&class_name,"CrispyDoomBridge");sn_new(&parent_name,"RefCounted");sn_new(&empty_name,"");str_new(&empty_string,"");
    Builtin resize={0};sn_new(&resize,"resize");bytes_resize=builtin_method(GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY,&resize,848867239);destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&resize);
    GDExtensionClassCreationInfo2 ci={0};ci.is_exposed=1;ci.create_instance_func=create_instance;ci.free_instance_func=free_instance;
    register_class(library,&class_name,&parent_name,&ci);
    const char *names[]={"open_core","step_core","snapshot_json","map_json","build_info_json","framebuffer","close_core","dimensions_json"};
    for(int id=0;id<8;id++) {
        Builtin name={0},arg_names[7]={0};sn_new(&name,names[id]);
        GDExtensionPropertyInfo ret={0},args[7]={0};GDExtensionClassMethodArgumentMetadata meta[7]={0};
        ret.type=id==FRAMEBUFFER?GDEXTENSION_VARIANT_TYPE_PACKED_BYTE_ARRAY:GDEXTENSION_VARIANT_TYPE_STRING;
        ret.name=&empty_name;ret.class_name=&empty_name;ret.hint_string=&empty_string;ret.usage=6;
        for(int i=0;i<counts[id];i++){char text[8];snprintf(text,sizeof(text),"arg%d",i);sn_new(&arg_names[i],text);args[i]=ret;args[i].name=&arg_names[i];args[i].type=id==OPEN&&i<4?GDEXTENSION_VARIANT_TYPE_STRING:GDEXTENSION_VARIANT_TYPE_INT;}
        GDExtensionClassMethodInfo mi={0};mi.name=&name;mi.method_userdata=(void*)(intptr_t)id;mi.call_func=dispatch;mi.method_flags=GDEXTENSION_METHOD_FLAG_NORMAL;mi.has_return_value=1;mi.return_value_info=&ret;mi.argument_count=counts[id];mi.arguments_info=args;mi.arguments_metadata=meta;
        register_method(library,&class_name,&mi);destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&name);
        for(int i=0;i<counts[id];i++)destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&arg_names[i]);
    }
}
static void deinitialize(void *unused,GDExtensionInitializationLevel level) {
    (void)unused;if(level!=GDEXTENSION_INITIALIZATION_SCENE)return;
    unregister_class(library,&class_name);
    destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&class_name);destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&parent_name);destructor(GDEXTENSION_VARIANT_TYPE_STRING_NAME)(&empty_name);destructor(GDEXTENSION_VARIANT_TYPE_STRING)(&empty_string);
}
__declspec(dllexport) GDExtensionBool etndoom_m0_init(GDExtensionInterfaceGetProcAddress get,
 GDExtensionClassLibraryPtr lib,GDExtensionInitialization *init) {
    library=lib;
#define API(var,type,name) do { GDExtensionInterfaceFunctionPtr address=get(name); _Static_assert(sizeof(var)==sizeof(address),"Function pointer ABI mismatch"); memcpy(&var,&address,sizeof(var));if(!var)return 0; } while(0)
    API(sn_new,GDExtensionInterfaceStringNameNewWithUtf8Chars,"string_name_new_with_utf8_chars");
    API(str_new,GDExtensionInterfaceStringNewWithUtf8Chars,"string_new_with_utf8_chars");
    API(str_utf8,GDExtensionInterfaceStringToUtf8Chars,"string_to_utf8_chars");
    API(from_type,GDExtensionInterfaceGetVariantFromTypeConstructor,"get_variant_from_type_constructor");
    API(to_type,GDExtensionInterfaceGetVariantToTypeConstructor,"get_variant_to_type_constructor");
    API(destructor,GDExtensionInterfaceVariantGetPtrDestructor,"variant_get_ptr_destructor");
    API(constructor,GDExtensionInterfaceVariantGetPtrConstructor,"variant_get_ptr_constructor");
    API(builtin_method,GDExtensionInterfaceVariantGetPtrBuiltinMethod,"variant_get_ptr_builtin_method");
    API(byte_index,GDExtensionInterfacePackedByteArrayOperatorIndex,"packed_byte_array_operator_index");
    API(construct_object,GDExtensionInterfaceClassdbConstructObject,"classdb_construct_object");
    API(set_instance,GDExtensionInterfaceObjectSetInstance,"object_set_instance");
    API(register_class,GDExtensionInterfaceClassdbRegisterExtensionClass2,"classdb_register_extension_class2");
    API(register_method,GDExtensionInterfaceClassdbRegisterExtensionClassMethod,"classdb_register_extension_class_method");
    API(unregister_class,GDExtensionInterfaceClassdbUnregisterExtensionClass,"classdb_unregister_extension_class");
    API(variant_type,GDExtensionInterfaceVariantGetType,"variant_get_type");
#undef API
    init->minimum_initialization_level=GDEXTENSION_INITIALIZATION_SCENE;init->initialize=initialize;init->deinitialize=deinitialize;init->userdata=NULL;return 1;
}
