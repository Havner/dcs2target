#include<iostream>
#include<fstream>
#include<sstream>
#include<string>
#include<map>
#include<list>
#include<vector>
#include<stdlib.h>

#include<dirent.h>
#include<sys/stat.h>

const std::string gPhase1 = "phase1/";
const std::string gPhase2 = "phase2/";
const std::string gPhase2raw = "phase2_raw/";
const std::string gFileEnds = "_keyboard_default.txt";

#define COUNT_OF(x) ((sizeof(x)/sizeof(0[x])) / ((size_t)(!(sizeof(x) % sizeof(0[x])))))
#define ERROR(reason) do { std::cout << __FUNCTION__ << "(): " << __LINE__ << ": " << reason << '\n'; exit(1); } while(0)

typedef std::map<std::string, std::string> StringMap;
typedef std::vector<std::string> StringVector;
typedef std::list<std::string> StringList;
typedef std::map<std::string, StringMap> MapMap;

StringMap gModMap;
StringMap gKeyMap;

struct Mapping {
	std::string lua;
	std::string target;
};

Mapping gModifiers[] = {
	{ "LCtrl",  "L_CTL"   },
	{ "RCtrl",  "R_CTL"   },
	{ "LShift", "L_SHIFT" },
	{ "RShift", "R_SHIFT" },
	{ "LAlt",   "L_ALT"   },
	{ "RAlt",   "R_ALT"   },
	{ "LWin",   "L_WIN"   },
	{ "RWin",   "R_WIN"   }
};

std::string trim(const std::string &str,
                 const std::string &whitespace = " \t")
{
	const size_t begin = str.find_first_not_of(whitespace);
	if (begin == std::string::npos)
		return "";

	const size_t end = str.find_last_not_of(whitespace);
	const size_t range = end - begin + 1;

	return str.substr(begin, range);
}

void printMap(StringMap &map)
{
	for(StringMap::const_iterator it = map.begin(); it != map.end(); ++it)
		std::cout << it->first << " => " << it->second << '\n';
}

void loadModMap()
{
	for (size_t i = 0; i < COUNT_OF(gModifiers); ++i)
		gModMap.insert(StringMap::value_type(gModifiers[i].lua, gModifiers[i].target));
}

void loadKeyMap(const std::string &f)
{
	std::ifstream in(f.c_str());

	gKeyMap.clear();

	if (!in.is_open())
		ERROR("can't file keymap file: " << f);

	for (std::string line; std::getline(in, line); )
	{
		std::istringstream iss(line);
		std::string lua, target;
		if (!(iss >> lua >> target))
			ERROR("parse error");

		gKeyMap.insert(StringMap::value_type(lua, target));
	}
}

std::string convKey(const std::string &k, StringMap &m)
{
	std::string ret = m[k];

	if (ret.empty())
		ERROR("key not mapped: [" << k << "]");

	return ret;
}

std::string convShortcut(const std::string &s)
{
	std::istringstream iss(s);
	std::string key, ret;
	StringVector v;
	StringList l;

	while (std::getline(iss, key, ' '))
		v.push_back(key);

	if (v.empty())
		ERROR("empty key shortcut");

	for (StringVector::const_iterator it = v.begin(); it != v.end(); ++it)
	{
		if (it->substr(0, 3) == "JOY")  // WTF Mig-21?
		{
			l.clear();
			l.push_front("USB[0x00]");
			break;
		}

		if (it == v.begin())
			l.push_front(convKey(*it, gKeyMap));
		else
			l.push_front(convKey(*it, gModMap));
	}

	for (StringList::const_iterator it = l.begin(); it != l.end(); ++it)
	{
		if (it != l.begin())
			ret += "+";
		ret += *it;
	}
	
	return ret;
}

void replaceAll(std::string& str, const std::string& from, const std::string& to)
{
	if(from.empty())
		return;
	size_t start_pos = 0;
	while((start_pos = str.find(from, start_pos)) != std::string::npos)
	{
		str.replace(start_pos, from.length(), to);
		start_pos += to.length(); // In case 'to' contains 'from', like replacing 'x' with 'yx'
	}
}

std::string fixName(const std::string &s)
{
	std::string ret = s;

	replaceAll(ret, " - ", "_");
	replaceAll(ret, " / ", "_");
	replaceAll(ret, ". ", "_");
	replaceAll(ret, " ", "_");
	replaceAll(ret, "-", "_");
	replaceAll(ret, ",", "_");
	replaceAll(ret, ".", "_");
	replaceAll(ret, "#", "");
	replaceAll(ret, "'", "");
	replaceAll(ret, ":", "_");
	replaceAll(ret, "+", "_");
	replaceAll(ret, "(", "_");
	replaceAll(ret, ")", "_");
	replaceAll(ret, "/", "_");
	replaceAll(ret, "%", "_");
	replaceAll(ret, "&", "and");

	// TM defines can't start with a number
	if (ret[0] >= '0' && ret[0] <= '9')
		ret = "x" + ret;

	return ret;
}

void doPlane(const std::string &lua, const std::string &target)
{
	std::string endl = "\r\n";

	MapMap cats;
	std::ifstream in(lua.c_str());
	std::ofstream dups;

	for (std::string line; std::getline(in, line); )
	{
		StringVector v;
		std::string sect;
		std::istringstream iss(line);

		while (std::getline(iss, sect, '\t'))
			v.push_back(trim(sect, "\r"));

		if (v.size() != 3)
			ERROR("each line should have a shortcut, a name and a category separated by tab");

		v[0] = convShortcut(trim(v[0], "\""));

		// TODO: deal with dups between categories
		StringMap::iterator it;
		if ((it = cats[v[2]].find(v[1])) != cats[v[2]].end())
		{
			std::string target_dup = target + ".dup";
			if (!dups.is_open())
				dups.open(target_dup.c_str());

			dups << "define\t" << fixName(it->first) << "\t" << it->second << "\t// " << v[2] << ": " << it->first << endl;

			cats[v[2]].erase(it);
		}
		cats[v[2]].insert(StringMap::value_type(v[1], v[0]));
	}

	std::ofstream out(target.c_str());

	out << "// ------------------------------------------ DCS------------------------------------------";
	out << endl << endl << endl;
	out << "// ------------------------------------------  T.A.R.G.E.T Macros File ------------------------------------------";
	out << endl;

	for (MapMap::const_iterator it = cats.begin(); it != cats.end(); ++it)
	{
		std::string cat_name = it->first;
		StringMap cat = it->second;

		out << endl << endl;
		out << "// " << cat_name << " **********************";
		out << endl << endl << endl;

		for (StringMap::const_iterator it = cat.begin(); it != cat.end(); ++it)
			out << "define\t" << fixName(it->first) << "\t" << it->second << "\t//" << it->first << endl;
	}	
}

StringVector findFiles(const std::string &d)
{
	StringVector ret;
	DIR *dir = opendir(d.c_str());
	if (dir == NULL)
		ERROR("could not open dir: " << d);

	struct dirent *ent;
	while ((ent = readdir(dir)) != NULL)
	{
		if (ent->d_type == DT_REG)
		{
			std::string file(ent->d_name);
			size_t pos = file.rfind(gFileEnds);
			if (pos != std::string::npos &&pos == file.size() - gFileEnds.size())
				ret.push_back(file);
		}
	}

	return ret;
}

std::string getPlaneName(const std::string &f)
{
	std::string ret = f.substr(0, f.size() - gFileEnds.size());
	ret = "DCS_" + ret + ".ttm";
	return ret;
}

int main(int argc, char *argv[])
{
	loadModMap();
	StringVector files = findFiles(gPhase1);

	mkdir(gPhase2.c_str(), 0755);
	loadKeyMap("dcs2target_keymap.txt");
	for (size_t i = 0; i < files.size(); ++i)
		doPlane(gPhase1 + files[i], gPhase2 + getPlaneName(files[i]));

	mkdir(gPhase2raw.c_str(), 0755);
	loadKeyMap("dcs2target_keymap_raw.txt");
	for (size_t i = 0; i < files.size(); ++i)
		doPlane(gPhase1 + files[i], gPhase2raw + getPlaneName(files[i]));

	return 0;
}
