# Adapted from https://github.com/ros/catkin/blob/kinetic-devel/cmake/test/tests.cmake

function(catkin_run_tests_target type name xunit_filename)
  cmake_parse_arguments(_testing "" "WORKING_DIRECTORY" "COMMAND;DEPENDENCIES" ${ARGN})
  if(_testing_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "catkin_run_tests_target() called with unused arguments: ${_testing_UNPARSED_ARGUMENTS}")
  endif()

  # Friendly error message for ros/catkin#961
  if(TARGET run_tests_${PROJECT_NAME} AND NOT TARGET _run_tests_${PROJECT_NAME})
    message(FATAL_ERROR "catkin_run_tests_target() needs to create a target called `run_tests_${PROJECT_NAME}`, but it already exists. Please rename the existing `run_tests_${PROJECT_NAME}` target/executable/library to something else.")
  endif()

  # create meta target to trigger all tests of a project
  if(NOT TARGET run_tests_${PROJECT_NAME})
    add_custom_target(run_tests_${PROJECT_NAME})
    # create hidden meta target which depends on hidden test targets which depend on clean_test_results
    add_custom_target(_run_tests_${PROJECT_NAME})
    # run_tests depends on this hidden target hierarchy to clear test results before running all tests
    add_dependencies(run_tests _run_tests_${PROJECT_NAME})
  endif()
  # create meta target to trigger all tests of a specific type of a project
  if(NOT TARGET run_tests_${PROJECT_NAME}_${type})
    add_custom_target(run_tests_${PROJECT_NAME}_${type})
    add_dependencies(run_tests_${PROJECT_NAME} run_tests_${PROJECT_NAME}_${type})
    # hidden meta target which depends on hidden test targets which depend on clean_test_results
    add_custom_target(_run_tests_${PROJECT_NAME}_${type})
    add_dependencies(_run_tests_${PROJECT_NAME} _run_tests_${PROJECT_NAME}_${type})
  endif()
  if(NOT DEFINED CATKIN_ENABLE_TESTING OR CATKIN_ENABLE_TESTING)
    # create target for test execution
    set(results ${CATKIN_TEST_RESULTS_DIR}/${PROJECT_NAME}/${xunit_filename})
    if (_testing_WORKING_DIRECTORY)
      set(working_dir_arg "--working-dir" ${_testing_WORKING_DIRECTORY})
    endif()
    assert(CATKIN_ENV)
    set(cmd_wrapper ${CATKIN_ENV} ${PYTHON_EXECUTABLE}
	${MAIN_WORKSPACE}/test/run_tests.py ${results} ${working_dir_arg})
    # for ctest the command needs to return non-zero if any test failed
    set(cmd ${cmd_wrapper} "--return-code" ${_testing_COMMAND})
    add_test(NAME _ctest_${PROJECT_NAME}_${type}_${name} COMMAND ${cmd})
    # for the run_tests target the command needs to return zero so that testing is not aborted
    set(cmd ${cmd_wrapper} ${_testing_COMMAND})
    add_custom_target(run_tests_${PROJECT_NAME}_${type}_${name}
      COMMAND ${cmd}
      VERBATIM
    )
  else()
    # create empty dummy target
    set(cmd "${CMAKE_COMMAND}" "-E" "echo" "Skipping test target \\'run_tests_${PROJECT_NAME}_${type}_${name}\\'. Enable testing via -DCATKIN_ENABLE_TESTING.")
    add_custom_target(run_tests_${PROJECT_NAME}_${type}_${name} ${cmd})
  endif()
  add_dependencies(run_tests_${PROJECT_NAME}_${type} run_tests_${PROJECT_NAME}_${type}_${name})
  if(_testing_DEPENDENCIES)
    add_dependencies(run_tests_${PROJECT_NAME}_${type}_${name} ${_testing_DEPENDENCIES})
  endif()
  # hidden test target which depends on building all tests and cleaning test results
  add_custom_target(_run_tests_${PROJECT_NAME}_${type}_${name}
    COMMAND ${cmd}
    VERBATIM
  )
  add_dependencies(_run_tests_${PROJECT_NAME}_${type} _run_tests_${PROJECT_NAME}_${type}_${name})

  # create target to clean project specific test results
  if(NOT TARGET clean_test_results_${PROJECT_NAME})
    add_custom_target(clean_test_results_${PROJECT_NAME}
      COMMAND ${PYTHON_EXECUTABLE} "${catkin_EXTRAS_DIR}/test/remove_test_results.py" "${CATKIN_TEST_RESULTS_DIR}/${PROJECT_NAME}"
      VERBATIM
    )
  endif()
  add_dependencies(_run_tests_${PROJECT_NAME}_${type}_${name} clean_test_results_${PROJECT_NAME} tests ${_testing_DEPENDENCIES})
endfunction()
