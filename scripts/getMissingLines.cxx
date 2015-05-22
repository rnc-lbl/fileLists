// This is a program to get the list of lines from a one file
// that do not exist in another file.
//
// To be used to get the list of missing files from a subset file list compared 
// to a list of all files.
//
// To compile:
// g++ -W -Wall -Wextra -pedantic -std=c++0x getMissingLines.cxx -o getMissingLines
// (gcc > 4.7) g++ -W -Wall -Wextra -pedantic -std=c++11 getMissingLines.cxx -o getMissingLines
//
// Usage:
// ./getMissingLines subsetFiles.list allFiles.list
//
// ////////////////////////////////////////////
//  Authors:
//    Mustafa Mustafa (mmustafa@lbl.gov)
// ////////////////////////////////////////////


#include <iostream>
#include <string>
#include <fstream>
#include <unordered_set>

using namespace std;

int main(int argc, char** argv)
{
  if(argc!=3)
  {
    cout<<"Usage: "<<argv[0]<<" "<<"subsetFiles.list"<<" "<<"allFiles.list"<<endl;
    return 1;
  }

  // make a hash table of lines in the subset list
  unordered_set<string> subsetFiles;

  ifstream fsSubsetFiles(argv[1]);
  if(fsSubsetFiles.is_open())
  {
    string line;
    while(getline(fsSubsetFiles,line))
    {
      subsetFiles.insert(line);
    }
  }
  else
  {
    cout<<"Can not open "<<argv[1]<<endl;
    return 1;
  }

  fsSubsetFiles.close();

  // check which lines in the allFiles don't exist in the subset files
  ifstream fsAllFiles(argv[2]);
  if(fsAllFiles.is_open())
  {
    string line;
    while(getline(fsAllFiles,line))
    {
      auto search = subsetFiles.find(line);

      if(search == subsetFiles.end())
      {
        cout<<line<<endl;
      }
    }
  }
  else
  {
    cout<<"Can not open "<<argv[2]<<endl;
    return 1;
  }

  fsAllFiles.close();

  return 0;
}
