macro(evaLUAtion_configure_linker project_name)
  set(evaLUAtion_USER_LINKER_OPTION
    "DEFAULT"
      CACHE STRING "Linker to be used")
    set(evaLUAtion_USER_LINKER_OPTION_VALUES "DEFAULT" "SYSTEM" "LLD" "GOLD" "BFD" "MOLD" "SOLD" "APPLE_CLASSIC" "MSVC")
  set_property(CACHE evaLUAtion_USER_LINKER_OPTION PROPERTY STRINGS ${evaLUAtion_USER_LINKER_OPTION_VALUES})
  list(
    FIND
    evaLUAtion_USER_LINKER_OPTION_VALUES
    ${evaLUAtion_USER_LINKER_OPTION}
    evaLUAtion_USER_LINKER_OPTION_INDEX)

  if(${evaLUAtion_USER_LINKER_OPTION_INDEX} EQUAL -1)
    message(
      STATUS
        "Using custom linker: '${evaLUAtion_USER_LINKER_OPTION}', explicitly supported entries are ${evaLUAtion_USER_LINKER_OPTION_VALUES}")
  endif()

  set_target_properties(${project_name} PROPERTIES LINKER_TYPE "${evaLUAtion_USER_LINKER_OPTION}")
endmacro()
